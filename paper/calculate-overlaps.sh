#!/bin/bash

SETTINGS=$1
OUTPUT_FILE=$2

source ${SETTINGS}

RUN_QUERY="docker exec -i dev.ewascatalog_db mysql -uroot -p${MYSQL_ROOT_PASSWORD} ewascatalog"

${RUN_QUERY} < add-columns.sql
${RUN_QUERY} < calculate-overlaps.sql > ${OUTPUT_FILE}
