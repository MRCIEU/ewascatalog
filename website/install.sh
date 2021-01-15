#!/bin/bash

WEBSITE_DIR="$1"
FILE_DIR="$2"
SETTINGS="$3"

## Prepare to copy
mkdir -p ${WEBSITE_DIR}

## delete old version
rm -rf ${WEBSITE_DIR}/catalog
rm -rf ${WEBSITE_DIR}/website

## copy the website files
cp -rv website/website/* ${WEBSITE_DIR}

## copy over settings.env
cp ${SETTINGS} ${WEBSITE_DIR}

## create directory for temporary files
mkdir -p ${WEBSITE_DIR}/catalog/static/tmp

## copy and gzip ewas catalog download files
mkdir -p ${WEBSITE_DIR}/catalog/static/docs
gzip -c ${FILE_DIR}/ewas-sum-stats/combined_data/studies.txt > ${WEBSITE_DIR}/catalog/static/docs/ewascatalog-studies.txt.gz
gzip -c ${FILE_DIR}/ewas-sum-stats/combined_data/results.txt > ${WEBSITE_DIR}/catalog/static/docs/ewascatalog-results.txt.gz
# cp ${FILE_DIR}/catalog-download/ewascatalog.txt.gz \
#    ${WEBSITE_DIR}/catalog/static/docs
## copy results template for uploads
cp ${FILE_DIR}/ewas-sum-stats/results_template.csv \
   ${WEBSITE_DIR}/catalog/static/docs

#chmod -R o-rwx ${WEBSITE_DIR}
#chgrp -R www-data ${WEBSITE_DIR}
#chmod -R g-w ${WEBSITE_DIR}
#chmod -R g+w ${WEBSITE_DIR}/catalog/static/tmp
