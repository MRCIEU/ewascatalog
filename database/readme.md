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

All information on how to upload new data to the database can be found in the [published-data-extraction](../published-data-extraction/readme.md) directory.

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
## Show tables to decide which to delete
${ROOT_CMD} ${DB} -e "show tables;"
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


