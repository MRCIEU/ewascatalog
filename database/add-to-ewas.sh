#!/bin/bash

SETTINGS=$1
FILE_DIR=$2

source ${SETTINGS}

ROOT_CMD="mysql -uroot -p${MYSQL_ROOT_PASSWORD}"
USER_CMD="mysql -u${DATABASE_USER} -p${DATABASE_PASSWORD}"

today=$(date +'%Y-%m-%d')
# printf "%s\t %s" "Date" "EWAS Added" >> ${FILE_DIR}/log-file.tsv

# put the data in the database
while read id; do
	echo "$id"
	# Make new results and studies tables in the sql database
	${ROOT_CMD} ${DB} < add-to-ewas-table.sql
	${ROOT_CMD} ${DB} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/ewas-sum-stats/study-data/${id}/studies.txt' INTO TABLE new_studies LINES TERMINATED BY '\n' IGNORE 1 LINES"
	${ROOT_CMD} ${DB} -e "LOAD DATA LOCAL INFILE '${FILE_DIR}/ewas-sum-stats/study-data/${id}/results.txt' INTO TABLE new_results LINES TERMINATED BY '\n' IGNORE 1 LINES"

	# Add assocs column to new_studies
	${ROOT_CMD} ${DB} -e "ALTER TABLE new_studies ADD column assocs INT"

	# Add these to the existing studies and results tables
	${ROOT_CMD} ${DB} -e "INSERT INTO studies SELECT * FROM new_studies"
	${ROOT_CMD} ${DB} -e "INSERT INTO results SELECT * FROM new_results"

	# Remove old datafiles
	rm -rf ${FILE_DIR}/ewas-sum-stats/to-add/${id}

	# Add new data to combined data
	tail -n +2 -q ${FILE_DIR}/ewas-sum-stats/study-data/${id}/studies.txt >> ${FILE_DIR}/ewas-sum-stats/combined_data/studies.txt
	tail -n +2 -q ${FILE_DIR}/ewas-sum-stats/study-data/${id}/results.txt >> ${FILE_DIR}/ewas-sum-stats/combined_data/results.txt

	# Add study ID to log file
	printf "\n%s\t %s" $today $id >> ${FILE_DIR}/log-file.tsv

done <${FILE_DIR}/ewas-sum-stats/studies-to-add.txt

# Add N EWAS to short log file
# printf "%s\t %s" "Date" "N EWAS Added" >> ${FILE_DIR}/short-log-file.tsv
n_ewas=$(wc -l < ${FILE_DIR}/ewas-sum-stats/studies-to-add.txt)
printf "\n%s\t %s" $today $n_ewas >> ${FILE_DIR}/short-log-file.tsv

# Remove all studies from "studies-to-add.txt"
> ${FILE_DIR}/ewas-sum-stats/studies-to-add.txt

## Add counts to tables (number of associations and publications)
## in order to speed up generating the 'splash' page
${ROOT_CMD} ${DB} < add-counts-to-tables.sql
