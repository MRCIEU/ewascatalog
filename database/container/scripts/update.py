#!/usr/bin/env python3

import sys
import os
import subprocess
import pandas as pd
from sqlalchemy import create_engine, text

DB_USER = os.environ['DATABASE_USER']
DB_PASSWORD = os.environ['DATABASE_PASSWORD']
DB_HOST = os.environ['DATABASE_HOST']
DB_NAME = os.environ['DATABASE_NAME']
DB_PORT = os.environ['DATABASE_PORT']
MYSQL_ROOT_PASSWORD = os.environ['MYSQL_ROOT_PASSWORD']

STUDY_FIELDS = [
    "author","consortium","pmid","date","trait","efo",
    "analysis","source","outcome","exposure","covariates",
    "outcome_units","exposure_units","methylation_array","tissue",
    "further_details","n","n_cohorts",
    "age","sex", "ethnicity"]

RESULT_FIELDS = ["cpg","beta","se","p","details"]

MAX_P = 1e-4

def get_existing_study_ids(engine):
    """
    Returns a set of study IDs already present in the database.
    """
    query = text("SELECT study_id FROM studies")
    with engine.connect() as conn:
        result = conn.execute(query)
        return set(row[0] for row in result)

def get_study_directories(base_path):
    """
    Returns a list of subdirectories in the given base path.
    """
    if not os.path.isdir(base_path):
        raise ValueError(f"Directory not found: {base_path}")
    
    return [d for d in os.listdir(base_path)
            if os.path.isdir(os.path.join(base_path, d))]

def get_study_id_col(df):
    """
    Extracts the study ID from the given DataFrame.
    Assumes the study ID is in a column named 'studyid' or 'study_id'.
    """
    if "studyid" in df.columns:
        return df['studyid']
    elif "study_id" in df.columns:
        return df['study_id']
    else:
        raise ValueError("Study ID column not found in DataFrame")

def get_studies(base_dir):
    """
    Reads the studies.txt file and returns a set of unique study IDs.
    """
    studies_file = os.path.join(base_dir, "studies.txt")
    df = pd.read_csv(studies_file, sep="\t")
    df.columns = df.columns.str.lower()
    return set(get_study_id_col(df))

def import_study(engine, base_dir, study_id):
    """
    Imports a single study into the database,
    including both study information and summary statistics.
    """
    ## save study information
    print(f" Importing study {study_id} ...")
    studies_file = os.path.join(base_dir, "studies.txt")
    df = pd.read_csv(studies_file, sep="\t")
    df.columns = df.columns.str.lower()
    df = df[get_study_id_col(df) == study_id]
    if "ethnicity" not in df.columns:
        if "ancestry" in df.columns:
            df.rename(columns={"ancestry": "ethnicity"}, inplace=True)
        else:
            df["ethnicity"] = None
    df = df[STUDY_FIELDS]
    df['study_id'] = study_id
    df.to_sql('studies', con=engine, if_exists='append', index=False)
    ## save summary statistics
    results_file = os.path.join(base_dir, "results.txt")
    df = pd.read_csv(results_file, sep='\t')
    df.columns = df.columns.str.lower()
    df = df[get_study_id_col(df) == study_id]
    df = df[RESULT_FIELDS]
    df = df[df['p'] < MAX_P]
    df['study_id'] = study_id
    df.to_sql('results', con=engine, if_exists='append', index=False)
    print(f" Imported {len(df)} statistics for study {study_id}")
    return len(df)

def import_studies(engine, base_dir, existing_studies):
    """
    Imports all studies from the given base directory
    that are not already in the database.
    """
    num_imported = 0
    try:
        studies_in_file = get_studies(base_dir)
        new_studies = studies_in_file - existing_studies
        if new_studies:
            print(f" Importing from {base_dir} ...")
        for study_id in new_studies:
            try:
                import_study(engine, base_dir, study_id)
                num_imported += 1
            except Exception as e:
                print(f" Error importing {study_id}: {e}")
    except Exception as e:
        print(f" Error processing {base_dir}: {e}")
    return num_imported

def save_downloads(engine, base_dir):
    """
    Saves database to a file for download from the website.
    """
    print("Saving database for download ...")
    try:        
        query = text("SELECT * FROM studies")
        with engine.connect() as conn:
            result = conn.execute(query)
            df = pd.DataFrame(result.fetchall(), columns=result.keys())
            df.to_csv(
                os.path.join(base_dir, "studies.txt.gz"),
                sep="\t", index=False, compression='gzip')
        query = text("SELECT * FROM results JOIN cpgs ON results.cpg = cpgs.cpg")
        with engine.connect() as conn:
            result = conn.execute(query)
            df = pd.DataFrame(result.fetchall(), columns=result.keys())
            df.to_csv(
                os.path.join(base_dir, "results.txt.gz"),
                sep="\t", index=False, compression='gzip')
    except Exception as e:
        print(f"Error generate download files: {e}")
        

def update_counts(add_counts_script):
    """
    Runs the SQL script to update counts in the database.
    """
    print("Updating counts ...")
    try:
        ret = subprocess.run(
            ['mysql',
             '-u', 'root',
             '-p' + MYSQL_ROOT_PASSWORD,
             DB_NAME],
            stdin=open(add_counts_script, 'r'),
            capture_output=True,
            text=True)
        if ret.returncode != 0:
            print(f"Error updating counts: {ret.stderr}")
        else:
            print("Counts updated successfully")
    except Exception as e:
        print(f"Error running counts update: {e}")

def main():
    if len(sys.argv) != 3:
        print("Usage: python script.py <base_directory> <add_counts_script>")
        sys.exit(1)

    base_directory = sys.argv[1]
    add_counts_script = sys.argv[2]

    try:
        engine = create_engine(
            f'mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'
        )
        study_dirs = get_study_directories(base_directory)
        print(f"Found {len(study_dirs)} study directories")
        existing_studies = get_existing_study_ids(engine)
        print(f"Found {len(existing_studies)} studies in the database")
        total = 0
        for study_dir in study_dirs:
            base_dir = os.path.join(base_directory, study_dir)
            total += import_studies(engine, base_dir, existing_studies)
        print(f"Imported {total} new studies")
        if total > 0:
            save_downloads(engine, base_directory)
            update_counts(add_counts_script)
                
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
