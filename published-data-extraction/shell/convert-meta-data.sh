#!/bin/bash

# in the published-data-extraction folder

## 0. = in readme.md
# 0. Move results into DROPBOX-FOLDER/DATE
# 0. download jotform data into recruits-data/combined-data/DATE/ as "jotform-rawdata-all.xlsx"
# 1. Copy results to recruits-data/combined-data/DATE/results/
# 2. run subset-jotform-data
# 3. remove full jotform dataset
# 4. convert the meta data

## CHANGE THE DATE!!
dropbox="/Users/tb13101/Dropbox/results"
date="2022-07-25"
recruit_data_path="recruits-data"
outpath="${recruit_data_path}/combined-data/"${date}"" 
raw_jotform_all=${outpath}"/jotform-rawdata-all.xlsx"
studies_file=${outpath}"/jotform-rawdata.xlsx"
pmid_file=${outpath}"/people-pmid.xlsx"
guide_file="templates/studies-example.xlsx"
res_dir=${outpath}"/results"
out_file=${outpath}"/studies-jotform.xlsx"
zen_file=${outpath}"/zen-file.xlsx"

# 1. 
mkdir -p ${res_dir}
cp "${dropbox}"/"${date}"/* ${res_dir}

# 2. 
Rscript R/subset-jotform-data.R ${recruit_data_path} ${date} ${raw_jotform_all} ${studies_file} ${pmid_file}

# 3. 
rm ${raw_jotform_all}

# 4.
python3 convert-meta-data.py ${studies_file} ${guide_file} ${res_dir} ${out_file} ${zen_file}

## IF IT DOESN'T WORK:
# open jotform studies file: open ${studies_file}
# check for 1. any that are likely external entries, 2. pmids of ones where it has failed
# look into the people-pmid.xlsx file to see who fucked it: open ${pmid_file}



### FOR EXTERNAL DATA
dropbox="/Users/tb13101/Dropbox/results"
date="2022-11-11"
external_data_path="external-data/data"
outpath="${external_data_path}/"${date}"" 
studies_file=${outpath}"/jotform-rawdata.xlsx"
guide_file="templates/studies-example.xlsx"
res_dir=${outpath}"/results"
out_file=${outpath}"/studies-jotform.xlsx"
zen_file=${outpath}"/zen-file.xlsx"

# 1.
mkdir -p ${res_dir}
## COPY EXTERNAL DATA TO FILE ${res_dir} HERE!
cp FILENAME ${res_dir}

# 4. 
python3 convert-meta-data.py ${studies_file} ${guide_file} ${res_dir} ${out_file} ${zen_file}