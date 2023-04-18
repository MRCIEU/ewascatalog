# ------------------------------------------------------------
# Convert jotform data into format 
# ------------------------------------------------------------

## modules
import os, re, sys
import pandas as pd

## arguments
studies_file = sys.argv[1]
example_file = sys.argv[2]
res_dir = sys.argv[3]
out_file = sys.argv[4]
zen_outfile = sys.argv[5]
print(sys.argv)
# studies_file = "recruits-data/combined-data/2021-08-23/jotform-rawdata.xlsx"
# example_file = "/Users/tb13101/Desktop/projects/phd/ewas_catalog/published-data-extraction/guidance-docs/templates/studies-example.xlsx"
# res_dir = "recruits-data/combined-data/2021-08-23/results"
# out_file = "recruits-data/combined-data/2021-08-23/studies-jotform.xlsx"
# zen_outfile = "recruits-data/combined-data/2021-08-23/zen-file.xlsx"

## read in data
studies = pd.read_excel(studies_file)

example_studies = pd.read_excel(example_file)
example_cols = list(example_studies.columns)

# ------------------------------------------------------------
# Edit the column names 
# ------------------------------------------------------------

## 
studies = studies.rename(columns=lambda x: x.strip())
colnames = list(studies.columns)
colnames_for_studies = {
	"First author": "Author", 
	"Cohorts or consortia used": "Cohorts_or_consortium", 
	"PubMed ID": "PMID", 
	"Date": "Date", 
	"Trait": "Trait", 
	"Trait units": "Trait_units", 
	"Was DNA methylation the outcome or exposure for your EWAS model?": "dnam_in_model", 
	"DNA methylation units": "dnam_units", 
	"Analysis": "Analysis", 
	"Results file name": "Results_file", 
	"Covariates (select all that apply. For meta-analysis entries select the covariates commonly used across studies.)": "Covariates", 
	"Source": "Source",
	"Other covariates": "Other_covariates", 
	"Technology used to measure methylation": "Methylation_Array", 
	"Tissue": "Tissue", 
	"Further details": "Further_Details", 
	"N": "N", 
	"N cohorts": "N_Cohorts", 
	"Age group (most common in EWAS)": "Age_group", 
	"Sex": "Sex", 
	"Ancestry (select all that apply)": "Ethnicity", 
	"Upload data to Zenodo": "Zenodo", 
	"Title of manuscript (or project)": "Title of manuscript", 
	"Description for Zenodo": "Description for Zenodo", 
	"Authors of manuscript": "All authors"
} 

## EFO in example, but not new form
## Other covariates in new form, but not example - needs to be combined with the covariates var
## Upload data to zenodo in new form, but not example (same with title of manuscript, description for zenodo and authors of manuscript)

new_studies = studies.rename(columns = colnames_for_studies)

# ------------------------------------------------------------
# Shuffle data around
# ------------------------------------------------------------

## Remove Submission Date
del new_studies["Submission Date"]
## Add EFO terms
new_studies["EFO"] = ""
new_colnames = list(new_studies.columns)
 
## Merge covariates and other covariates columns
other_covs = ", " + new_studies["Other_covariates"].fillna("")
other_covs = other_covs.replace(", ", "")
new_studies["Covariates"] = new_studies["Covariates"] + other_covs

## Take out zenodo stuff -- will just upload it manually
zen_cols = ["Zenodo", "Title of manuscript", "Description for Zenodo", "All authors"]
zen_df = new_studies[zen_cols]
new_studies.drop(zen_cols, axis = 1, inplace = True)

## Rearrange the order of the data.frames
col_check = all(item in new_colnames for item in example_cols)

if col_check == False:
	raise ValueError("Columns in new studies should contain all columns from the example studies data")
 
out_studies = new_studies[example_cols]

## Edit where there are newlines instead of commas 
out_studies = out_studies.replace(to_replace=r'\n', value=', ', regex=True)

# ------------------------------------------------------------
# Check the results files match those uploaded to dropbox
# ------------------------------------------------------------

## Add the name to the results file - as is displayed in dropbox folder
res_files = list(out_studies["Results_file"])

def rename(name, path):
    for root, dirs, files in os.walk(path):
        for file in files:
            if name in file:
                new_name = re.sub(".*- ", "", file)
                old_name = os.path.join(root, file)
                new_name = os.path.join(root, new_name)
                print("Old file name = "+old_name)
                print("New file name = "+new_name)
                os.rename(old_name, new_name)
                return True
 
 
for file in res_files:
	print(file)
	x = rename(file, res_dir)
	if x != True:
		err_msg = "File " + file + " wasn't found or renamed.\n" + "Please check the raw jotform meta-data." 
		raise ValueError(err_msg)
 
# ------------------------------------------------------------
# Write out the data
# ------------------------------------------------------------

out_studies.to_excel(out_file, sheet_name = "Data", index = False)
zen_df.to_excel(zen_outfile, index = False)