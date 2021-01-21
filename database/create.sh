#!/bin/bash

SETTINGS=$1
FILE_DIR=$2

source ${SETTINGS}

ROOT_CMD="mysql -uroot -p${MYSQL_ROOT_PASSWORD}"
USER_CMD="mysql -u${DATABASE_USER} -p${DATABASE_PASSWORD}"

mysqladmin ping -uroot --password=${MYSQL_ROOT_PASSWORD}
sleep 1m

##########################################################
## Initialise database
${ROOT_CMD} -e "use ${DB}" > /dev/null 2>&1
DB_EXISTS=`echo $?`

if [ ${DB_EXISTS} -eq 1 ]; then
    echo "Creating ${DB}"
    ${ROOT_CMD} -e "create database ${DB}"
fi

${ROOT_CMD} -e "grant select on *.* to '${DATABASE_USER}'@'%' identified by '${DATABASE_PASSWORD}'"

##########################################################
## Create CpG table
${ROOT_CMD} ${DB} -e "desc cpgs" > /dev/null 2>&1
TABLE_EXISTS=`echo $?`

if [ ${TABLE_EXISTS} -eq 1 ]; then
    echo "Creating cpgs table"
    ${ROOT_CMD} ${DB} < create-cpg-table.sql
    ${ROOT_CMD} ${DB} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/cpg_annotation.txt' INTO TABLE cpgs LINES TERMINATED BY '\n' IGNORE 1 LINES" 
fi

###########################################################
## Create gene table
${ROOT_CMD} ${DB} -e "desc genes" > /dev/null 2>&1
TABLE_EXISTS=`echo $?`

if [ ${TABLE_EXISTS} -eq 1 ]; then
    echo "Creating genes table"
    ${ROOT_CMD} ${DB} < create-gene-table.sql
    ${ROOT_CMD} ${DB} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/gene_annotation.txt' INTO TABLE genes LINES TERMINATED BY '\n' IGNORE 1 LINES"
fi


       
###########################################################
## Create EWAS table
${ROOT_CMD} ${DB} -e "desc results" > /dev/null 2>&1
TABLE_EXISTS=`echo $?`

if [ ${TABLE_EXISTS} -eq 1 ]; then
    echo "Creating results and studies tables"
    ${ROOT_CMD} ${DB} < create-ewas-table.sql
    ${ROOT_CMD} ${DB} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/ewas-sum-stats/combined_data/studies.txt' INTO TABLE studies LINES TERMINATED BY '\n' IGNORE 1 LINES"
    ${ROOT_CMD} ${DB} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/ewas-sum-stats/combined_data/results.txt' INTO TABLE results LINES TERMINATED BY '\n' IGNORE 1 LINES"
fi

##########################################################
## Add counts to tables (number of associations and publications)
## in order to speed up generating the 'splash' page

${ROOT_CMD} ${DB} < add-counts-to-tables.sql



## Ideally all of these queries should return 0, but these numbers aren't terrible:

  ## select count(distinct gene) from results where gene not in (select gene from genes);
  ## 8253
							   
  ## select count(distinct cpg) from results where cpg not in (select cpg from cpgs);
  ## 11600

  ## select count(distinct study_id) from results where study_id not in (select study_id from studies);
  ## 0

## Other issues: inconsistent linking of EFO terms to traits 
