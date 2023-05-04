# readme

Files and docs kept locally for published data extraction. Data extracted by the paid recruits or the data extraction team will be present (from May 2020), and will be present on the ewas catalog [sharepoint site](https://uob.sharepoint.com/teams/grp-ewas-catalog). 

Below we have the workflow for data extraction and the workflow getting data from authors of recent EWAS and below that are the directories and what they contain.

## Data extraction workflow 

### assign papers

If you are running this for the first time, please move the folder `data-to-enter` from the RDSF directory (in `RDSF_DIR/working/data/published-data-extraction` to this directory.

1. Run [`create-paper-master-list.R`](R/create-paper-master-list.R) to create a spreadsheet of publications which have been reviewed and noted whether data has been extracted.
2. Run [`extract-papers-to-add.R`](R/extract-papers-to-add.R) to create a spreadsheet of publications that still need to be extracted.
3. Run [`assign_papers.R`](R/assign_papers.R) to assign papers, put them in a spreadsheet and add the spreadsheet to the recruits' folders.

### Data extraction

1. Run the command: `bash shell/transfer-data.sh "to" "DATE-OF-EXTRACTION"` to put the assigned papers into the sharepoint folders
2. Go to the data extraction meeting
3. After the meeting run `bash shell/transfer-data.sh "from" "DATE-OF-EXTRACTION"` to get the data from the synced sharepoint folder
4. Then go to https://eu.jotform.com/tables/211644540717049 to download all meta-data from the jotform and put it into `recruits-data/combined-data/DATE-OF-EXTRACTION` and rename it `jotform-rawdata-all.xlsx`
5. Then move all summary data from the main dropbox directory folder (`results`) to one within that dropbox folder called `DATE-OF-EXTRACTION`

__NB: DATE-OF-EXTRACTION should be in the format of YYYY-mm-dd__

### Uploading data

Use [`data-checklist.xlsx`](recruits-data/data-checklist.xlsx) to keep track of what data has been uploaded. For each member of the data extraction team:

1. Check they've uploaded some results - if not then contact them
2. Run through [`convert-meta-data.sh`](shell/convert-meta-data.sh) in the `published-data-extraction` folder
3. Quickly check the `studies.xlsx` and/or `studies-jotform.xlsx` spreadsheet and the `results/` they uploaded to see if they're in the correct format (lots of notes on this on the sharepoint site)
4. Remove any rows in the `papers-to-add...` file that aren't filled in (double check the data for these rows aren't in the studies.xlsx spreadsheet)
5. If any studies haven't been finished then extract the data from these (would only be case if filling out the `studies.xlsx` spreadsheet rather than using jotform)
6. Combine studies and results files into one by running through [`combine-recruit-data.R`](R/combine-recruit-data.R)
7. Copy the data from `recruits-data/combined-data/DATE/` to `FILE_DIR/ewas-sum-stats/inhouse-data/` (local directory to test the catalog)
8. Change directory to the local ewas catalog web app directory and run `bash catalog prep-inhouse-data` - This will prepare the new data and output a file `"FILE_DIR/ewas-sum-stats/inhouse-data/failed_studies_DATE.tsv"` with any failed entries. 
9. Deal with failed entries
10. Then Run `bash catalog update-database` - This will add the new entries to the database.
11. Finally move the data onto the RDSF (at `"RDSF_DIR/working/data/files/ewas-sum-stats/inhouse-data"`) and the shark server when all errors have been fixed and run the commands in steps 6-8 again. TIP: Use `tmux` when on bp1 before logging into the shark server - step 10 can take some time and your connection to the server might break before it finishes
12. Copy the new full datasets from the shark server (`FILE_DIR/ewas-sum-stats/combined_data/studies.txt` and `FILE_DIR/ewas-sum-stats/combined_data/results.txt`) to the RDSF - same folder. 
	+ TIP: move the the files to the `old-data` folder before doing the transfer (MOVE NOT COPY) so that it's not possible to accidently overwrite the new data on the shark server
13. Celebrate if it all works

## Acquiring new EWAS data

**NOTE: People to email will be extracted by Paul Yousefi in the data extraction meetings. To assign the papers to Paul and get the information he collects follow the steps in `assign papers` and `Data extraction` above**

### Sending emails

0. Check Paul has extracted the data and it is in the correct folder (`recruits-data/Paul Yousefi/DATE-OF-EXTRACTION`)
1. Go into the [`external-data`](external-data) folder and run `python write-emails.py "DATE-OF-EXTRACTION"` to create emails that are saved in files named as the recipients email address
2. Email each author by copying and pasting the contents of their emails into an outlook message. 
3. Quickly read over the message and send it off

### Sorting data

**This should be done at the data extraction meeting after emails were sent**

1. Go to `external-data/data/DATE-OF-EXTRACTION` and open `papers-to-add-DATE-OF-EXTRACTION.xlsx`
2. Fill in the "contacted" and "data_received" columns
3. Email anyone who has been contacted but who hasn't provided data (see [`second-email-template`](external-data/second-email-template) for template)

**This should be done at the data extraction meeting after the second emails were sent**

4. Move data from the dropbox folder (e.g. `/Users/USERNAME/Dropbox/results`) to `external-data/data/DATE-OF-EXTRACTION/results`
5. Download the jotform data from here: https://eu.jotform.com/tables/211644540717049 into `external-data/data/DATE-OF-EXTRACTION` and rename it `jotform-rawdata.xlsx`
6. Run through [`convert-meta-data.sh`](shell/convert-meta-data.sh) in the `published-data-extraction` folder
7. Upload any data to Zenodo that needs to be uploaded there
8. Edit the `studies-jotform.xlsx` file and save as `studies.xlsx`
	+ Need to remove the category definitions from the "Age_group" column (i.e. the bits in brackets) and change the sheet name from "Data" to "data"
9. Sort results files out so they can be uploaded to the catalog
10. Follow steps 7-12 of [`Uploading data`](uploading-data)

**NOTE: People may email ewascatalog@outlook.com if they are about to publish a paper and want us to put the data into the catalog and/or onto Zenodo. If this happens then follow steps 4-10 of the section above - just make a directory to put the data into before starting.**

## Directories/files

### convert-meta-data.py

Script used to process meta-data from jotform.

### [R](R) 

Scripts that take data on published papers extracted from the [epigenetics-journal-club](https://github.com/MRCIEU/epigenetics-journal-club) R package and the EWAS Atlas and assign them to the extraction team.

### epigenetics-journal-club

Cloned version of the [epigenetics-journal-club](https://github.com/MRCIEU/epigenetics-journal-club) repo. This allows quick pulling of new papers added to the repo.

This is not committed to GitHub.

### external-data

Scripts/templates used to generate emails to send to authors of new EWAS and the data they send back. The data is not committed to GitHub.

### recruits-data 

Data extracted by the data extraction team (or paid recruits). These files may have been edited, but the originals can be found on the [sharepoint site](https://uob.sharepoint.com/teams/grp-ewas-catalog). The data files are not committed to GitHub.

### shell

Scripts for: 1. transferring data between local directory and the synced sharepoint directory, 2. processing meta-data from jotform.

### test

Some files used to test whether [`test-results.R`](R/test-results.R) works.