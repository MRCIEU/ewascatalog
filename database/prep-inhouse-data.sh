#!/bin/bash

SETTINGS=$1
FILE_DIR=$2

source ${SETTINGS}

# add in new directories to add!
echo "preparing inhouse data"
Rscript prep-inhouse-data.r "${FILE_DIR}"

