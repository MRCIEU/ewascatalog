# EWAS Catalog database

The scripts in this directory are for creating and populating the database.

The scripts are all copied to the docker container by the
[catalog](../catalog) script,
and then, in the container,
`create-annotations.sh` is executed to create
CpG and gene annotation text files
and `create.sh` is executed to
create and populate the database.

`create-annotations.sh` generates files
`cpg-annotation.txt` and `gene-annotation.txt` using R scripts
(in the `FILES_DIR` directory defined in [catalog](../catalog)).

`create.sh` uses these files to create the 'cpgs' and 'genes'
tables and files from `${FILES_DIR}/published-ewas` to create
the 'results' and 'studies' tables.

## Updating with new data

### Uploading via ewascatalog.org/upload/
This is a 3 step process:

1. Input study data on the website (at [ewascatalog.org/upload]) and upload the results file
   + Internally, the system (1) creates a folder with uploaded information and files in `${FILE_DIR}/ewas-sum-stats/to-add/` and then (2) runs `database/check-ewas-data.r` to check the upload and send a report to the uploader.
   
2. Run `bash catalog check-new-upload`
   + Internally, runs `database/prep-new-data.sh` applying `database/prep-new-data.r` to the contents of each directory in `${FILES_DIR}/ewas-sum-stats/to-add`. For each new study, a study ID and QC report are generated and saved along with study information in a new folder `${FILES_DIR}/ewas-sum-stats/published/${STUDY_ID}`. The new study ID is then added to the file `${FILES_DIR}/ewas-sum-stats/studies-to-add.txt`. 

3. Run `bash catalog update-database`
   + Internally, for each study listed in `${FILES_DIR}/ewas-sum-stats/studies-to-add.txt`, a new Zenodo DOI is created and EWAS info uploaded to zenodo (`database/generate-zenodo-doi.sh` which runs `database/zenodo.py`), and the EWAS is added to the database (`database/add-to-ewas.sh`). 

More details can be found [here](upload.md).

### Uploading EWAS data generated in-house

THIS NEEDS TO BE UPDATED!  



**Note**: These scripts are written so that each creation
command (create file/database/table) will be skipped if
the file/database/table has already been created.
If the item needs to be recreated, then it should be deleted.


## Direct access to the database

It is possible to get direct access to the running database
and experiment with changes.
```
## start a bash session in the database container
docker exec -it dev.ewascatalog_db bash
## start a mysql session (see settings.env for password) 
mysql -uroot -p${MYSQL_ROOT_PASSWORD} ewascatalog
```

A single table could be recreated by deleting that table
and then recreating the database.
Any existing table will be left as it is,
missing tables will be created.
```
## gain command-line access to the mysql container
docker exec -it dev.ewascatalog_db bash
## load variables for database access
source /code/settings.env
ROOT_CMD="mysql -uroot -p${MYSQL_ROOT_PASSWORD}"
## delete the entire database!
${ROOT_CMD} ${DB} -e "drop database ${DB}" 
## or just delete the cpgs table
${ROOT_CMD} ${DB} -e "drop table cpgs"
## recreate anything that was deleted using updated code/data files
bash catalog create-database
```

It is possible to get direct access to the running database
and experiment with changes.
```
## start a bash session in the database container
docker exec -it dev.ewascatalog_db bash
## start a mysql session (see settings.env for password) 
mysql -uroot -p${MYSQL_ROOT_PASSWORD} ewascatalog
```

Any `drop` commands in mysql should only take a few seconds. If after multiple minutes the command has not completed then some other dormant processes may be interfering. To solve this you will need to access the running database (as above) and follow the instructions [here](https://stackoverflow.com/questions/24496918/mysql-slow-drop-table-command).


