#!/usr/bin/env python3

"""
This script extracts EWAS information uploaded by users
(EWAS metadata in studies.csv, one row per EWAS,
and a summary statistics csv file for each EWAS)
and prepares them for import into the dataset
(studies.txt and results.txt).
"""

import sys
import os
import re
import pandas as pd
from collections import defaultdict
from sqlalchemy import create_engine, text

DB_USER = os.environ['DATABASE_USER']
DB_PASSWORD = os.environ['DATABASE_PASSWORD']
DB_NAME = os.environ['DATABASE_NAME']
SOCKET="/var/run/mysqld/mysql.sock"

OUTPUT_STUDY_FIELDS = [
    "author","consortium","pmid","date","trait","efo",
    "analysis","source","outcome","exposure","covariates",
    "outcome_units","exposure_units","methylation_array","tissue",
    "further_details","n","n_cohorts",
    "age","sex", "ethnicity"]

OUTPUT_RESULT_FIELDS = ["cpg","beta","se","p","details"]

STUDY_MAP = {
    "first author": "author", 
    "cohorts or consortia used": "consortium", 
    "pubmed id": "pmid" ,
    "date": "date",
    "trait": "trait",
    "trait units": "trait_units", 
    "was dna methylation the outcome or exposure for your ewas model?": "dnam_in_model",
    "dna methylation units": "dnam_units", 
    "analysis": "analysis",
    "covariates (select all that apply. for meta-analysis entries select the covariates commonly used across studies.)": "covariates",
    "results file name": "results_file",
    "source": "source",
    "other covariates": "other_covariates",
    "technology used to measure methylation": "methylation_array", 
    "tissue": "tissue",
    "further details": "further_details", 
    "n": "n",
    "n cohorts": "n_cohorts", 
    "age group (most common in ewas)": "age",
    "sex": "sex",
    "ancestry (select all that apply)": "ethnicity"}

RESULT_MAP = {
    "probe": "cpg",
    "cpg": "cpg",
    "site": "cpg",
    "markername": "cpg",
    "marker": "cpg",
    "beta": "beta",
    "b": "beta",
    "coef": "beta",
    "coefficient": "beta",
    "estimate": "beta",
    "effect": "beta",
    "est": "beta",
    "se": "se",
    "stderr": "se",
    "p": "p",
    "pval": "p",
    "pvalue": "p",
    "p-value": "p",
    "p.value": "p",
    "details": "details"}

def rename_and_filter_columns(df, col_map):
    """
    Renames columns in the DataFrame according to col_map
    and removes columns not in col_map.

    Parameters:
        df (pd.DataFrame): The input DataFrame.
        col_map (dict): Mapping from original to new column names.

    Returns:
        data frame with renamed and filtered columns.
    """
    df.columns = df.columns.str.lower()
    common_cols = [col for col in col_map if col in df.columns]
    df = df[common_cols].copy()
    reverse_map = defaultdict(list)
    for col in df.columns:
        new_col = col_map.get(col, col)
        reverse_map[new_col].append(col)
    duplicates_found = False
    for new_col, cols in reverse_map.items():
        if len(cols) > 1:
            print(f"Error: Unsure which of {cols} should be {new_col}")
            duplicates_found = True
    if duplicates_found:
        raise ValueError("Please resolve column ambiguities and rerun.")
    return df.rename(columns=col_map)

def get_existing_study_ids(engine):
    """
    Returns a set of study IDs already present in the database.
    """
    query = text("SELECT study_id FROM studies")
    with engine.connect() as conn:
        result = conn.execute(query)
        return set(row[0] for row in result)

def generate_study_id(row, existing_studies):
    row.index = row.index.str.lower()
    author = row['author'].replace(' ', '-')
    trait = row['trait'].lower().replace(' ', '_')    
    pmid = row['pmid'] if pd.notna(row['pmid']) else None
    if pd.notna(row['analysis']):
        analysis = row['analysis'].lower().replace(' ', '_')
    else:
        analysis = None
    parts = [str(x) for x in [pmid, author, trait, analysis] if x is not None]
    study_id = "_".join(parts)
    if study_id in existing_studies:
        raise ValueError(f"Generated study ID '{study_id}' for more than one study. Consider adding further info to the 'analysis' column to make it unique.")
    return study_id

def detect_column_sep(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        first_line = f.readline()
    comma_count = first_line.count(',')
    semicolon_count = first_line.count(';')
    tab_count = first_line.count('\t')
    max_count = max(comma_count, semicolon_count, tab_count)
    if tab_count == max_count:
        return '\t'
    elif semicolon_count == max_count:
        return ';'
    else:
        return ','

def detect_decimal_sep(filename, sep):
    with open(filename, encoding='utf-8') as f:
        lines = [next(f) for _ in range(5)]
    
    fields = []
    for line in lines[1:]:  # skip header
        fields.extend(line.strip().split(sep))
    
    comma_decimal = any(re.search(r'\d+,\d+', field) for field in fields)
    period_decimal = any(re.search(r'\d+\.\d+', field) for field in fields)
    
    if comma_decimal and not period_decimal:
        return ','
    elif period_decimal and not comma_decimal:
        return '.'
    raise ValueError("Unable to determine decimal separator. Please ensure the file uses consistent formatting and try again.")
        
def load_csv_or_tsv(filepath):
    """
    Loads a file that may be comma- or tab-separated into a pandas DataFrame.
    Tries to auto-detect the delimiter.
    """
    colsep = detect_column_sep(filepath)
    decsep = detect_decimal_sep(filepath,colsep)
    return pd.read_csv(filepath, delimiter=colsep, decimal=decsep, encoding='utf-8')

def prep_study(path, existing_studies):
    studies_file = os.path.join(path, "studies.csv")
    studies = pd.read_csv(studies_file, encoding='utf-8')
    studies = rename_and_filter_columns(studies, STUDY_MAP)
    studies['study_id'] = None
    studies['exposure'] = None
    studies['outcome'] = None
    studies['exposure_units'] = None
    studies['outcome_units'] = None
    if "efo" not in studies.columns:
        studies['efo'] = "EFO:0000001"
    missing_fields = [field for field in OUTPUT_STUDY_FIELDS if field not in studies.columns]
    if missing_fields:
        raise ValueError(f"Missing required fields in studies data: {missing_fields}")
    results = []
    for idx, row in studies.iterrows():
        study_id = generate_study_id(row, existing_studies)
        studies.at[idx,'study_id'] = study_id
        existing_studies.add(study_id)
    for idx, row in studies.iterrows():
        study_id = studies.at[idx,'study_id']
        print(f"    Processing study {study_id} ...")
        if "exposure " in row['dnam_in_model'].lower():
            studies.at[idx,'exposure'] = "DNA methylation"
            studies.at[idx,'outcome'] = row['trait']
            studies.at[idx,'outcome_units'] = row['trait_units']
            studies.at[idx,'exposure_units'] = row['dnam_units']
        else:
            studies.at[idx,'outcome'] = "DNA methylation"
            studies.at[idx,'exposure'] = row['trait']
            studies.at[idx,'outcome_units'] = row['dnam_units']
            studies.at[idx,'exposure_units'] = row['trait_units']
        results_file = os.path.join(path, row['results_file'])
        print(f"    Loading results from {results_file} ...")
        new_results = load_csv_or_tsv(results_file)
        new_results = rename_and_filter_columns(new_results, RESULT_MAP)
        new_results['study_id'] = study_id
        if "details" not in new_results.columns:
            new_results['details'] = ""
        missing_fields = [field for field in OUTPUT_RESULT_FIELDS if field not in new_results.columns]
        if missing_fields:
            raise ValueError(f"Missing required fields in results data for study {study_id}: {missing_fields}")
        if len(results) == 0:
            results = new_results
        else:
            results = pd.concat([results, new_results], ignore_index=True)
    results.to_csv(os.path.join(path, "results.txt"), sep="\t", index=False)
    studies.to_csv(os.path.join(path, "studies.txt"), sep="\t", index=False)
    print(f"    Finished processing in {path}.")

def main():
    if len(sys.argv) != 2:
        print("Usage: python prep.py <directory>")
        sys.exit(1)

    path = sys.argv[1]

    try:
        engine = create_engine(
            f'mysql+pymysql://{DB_USER}:{DB_PASSWORD}@localhost/{DB_NAME}?unix_socket={SOCKET}'
        )
        existing_studies = get_existing_study_ids(engine)

        if os.path.exists(os.path.join(path,"results.txt")) \
           or os.path.exists(os.path.join("studies.txt")):
            raise ValueError("Output files 'results.txt' or 'studies.txt' already exist in the specified directory. Please remove them before running this script.")
        
        prep_study(path, existing_studies)
                
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()













