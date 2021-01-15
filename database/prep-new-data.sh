#!/bin/bash

# BEFORE THIS SCRIPT REPORT SHOULD HAVE BEEN GENERATED!

SETTINGS=$1
FILE_DIR=$2

source ${SETTINGS}
# source ${FILE_DIR}/ewas-sum-stats/ewas-to-add.sh

declare -a NEW_DATA=()

# add in new directories to add!
PUB_PATH=/ewas-sum-stats/to-add
for dir in ${FILE_DIR}${PUB_PATH}/*/     # list directories in the form "/tmp/dirname/"
do
    dir=${dir%*/}
    NEW_DATA+=($dir)
done

NEW_DATA+=() # add filepath of summary stats completed in-house here

# echo "${NEW_DATA[@]}"

for dir in "${NEW_DATA[@]}"
do
	echo "preparing data in ${dir##*/}"
	Rscript prep-new-data.r "${dir}" "${FILE_DIR}"
done
