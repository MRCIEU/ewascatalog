#!/bin/bash

SETTINGS=$1

source ${SETTINGS}

mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "drop database if exists ${DB}"
