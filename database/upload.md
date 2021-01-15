## Summary and file paths for each step


### STEP1: UPLOAD FILES

Uploaded files are checked and saved in /files/ewas-sum-stats/to-add/STUDY-ID

Email sent to user with studies table and initial report



### STEP2: RUN "bash catalog check-new-upload"

All directories in /files/ewas-sum-stats/to-add/ are looped over and this is what is done:

A directory is created at /files/ewas-sum-stats/study-data/STUDY-ID

A report is made from the data and saved at the new directory

Files in /files/ewas-sum-stats/to-add/STUDY-ID are annotated, subset (to p<1x10-4) and moved to the new directory

STUDY-ID is added to /files/ewas-sum-stats/studies-to-add.txt



### STEP3: RUN "bash catalog update-database"

Data specified by /files/ewas-sum-stats/studies-to-add.txt is added to the mysql database and to the data in /files/ewas-sum-stats/combined_data/

Data is uploaded to zenodo (if this is the case)

The data is deleted from /files/ewas-sum-stats/to-add and study-ids are removed from /files/ewas-sum-stats/studies-to-add.txt


## Detailed summary of pipeline

### STEP1: UPLOAD FILES

**File upload**

User goes to the upload page and completes study form and uploads results file

Size of files checked: Studies < 10Mb and Results < ~2.5Gb

Files checked to make sure they're .csv files

Data is read into Python and written out into the temporary directory
* Study form: website/website/catalog/forms.py
* Functions to setup form, upload page and perform checks: website/website/catalog/upload.py and website/website/catalog/views.py

**Initial data checks**

After data is read into R, these checks are carried out:

Correct column names

Values in "required" columns are present:
* Studies: Author, Trait, Outcome, Exposure, Methylation_Array, Tissue
* Results: CpG, P

Values aren't too long (as defined in database/create-ewas-table.sql)

Values in results$CpG begin with a "c"

Values in results$P are between 0 and 1

If present, values in results$SE aren't negative
* Data check script: database/check-ewas-data.r

If any of the checks are failed then the user will be told why it failed (e.g. "Not all P values provided are between 0 and 1")

**Initial report**
If the data uploaded passes these checks then a report is generated that details:
* Names of files uploaded
* Dimensions of data
* Checks passed
* Top 10 sites (by p-value)

The data is also then moved from the temporary space to "/files/ewas-sum-stats/to-add/STUDY-ID/"
* Results file will be called DATETIME_results.csv
* Studies file will be called DATETIME_studies.csv

This report and the studies file is sent to the user via email and they are directed to a page that tells them they should have received an email at the email they provided and we'll get back to them soon with zenodo doi etc.
* Report is generated in database/check-ewas-data.r using the template in database/upload-report-one.rmd
* Email sent using code from: website/website/catalog/upload.py and website/website/catalog/views.py

### STEP2: RUN "bash catalog check-new-upload"

**More detailed report**

This loops through the directories in "/files/ewas-sum-stats/published/to-add/", for each directory it reads the data into R and does the following:

Generates StudyIDs

Annotates the results with the CpG annotations file

Generates another report that contains:
* Summary of associations by P-value
* Manhattan and qq-plot
* Whether EFO term is present
* Number of outliers when looking at effect estimate
* The array and number of rows in results
* Distributions of Betas + SEs
* A checklist at the top for us to go through and if it meets these criteria then we can add the data into the database

Subsets the results (P<1e-4)

Writes out the studies file as "studies.txt" and the results file as "results.txt" to "/files/ewas-sum-stats/published/STUDY-ID/"

Adds "STUDY-ID" to "/files/ewas-sum-stats/studies-to-add.txt"
* Uses database/prep-new-data.sh and database/prep-new-data.r
* Report template: database/upload-report-two.rmd

**After checking report**

May have to fill in EFO term if it wasn't provided

If data doesn't look right we can discuss it and then email the user asking them to check the data

If all good then move to next step

### STEP3: RUN "bash catalog update-database"

This loops through "/files/ewas-sum-stats/studies-to-add.txt" and:
* Generates zenodo DOIs
* Adds all the data to the database
* Adds data to "/files/ewas-sum-stats/combined_data/" for building database from scratch
* Deletes the data from "/files/ewas-sum-stats/to-add/"

Makes a new blank "studies-to-add.txt"
* generate-zenodo-doi.sh and zenodo.py for uploading to zenodo via API
* add-to-ewas.sh and add-to-ewas-table.sql  for adding results to catalog


### To-do

Add in code to make sure new "update-database" function will work with new in-house EWAS

Tidy up code  