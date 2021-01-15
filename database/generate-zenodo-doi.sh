#!/bin/bash

SETTINGS=$1
FILE_DIR=$2

source ${SETTINGS}

# put the data in the database
while read id; do
	echo "$id"

	# Create zenodo doi - to test use the sandbox token and make edits
	# 					  to zenodo.py (instructions in script)
	# python3 zenodo.py ${id} ${FILE_DIR} ${SANDBOX_TOKEN}
	python3 zenodo.py ${id} ${FILE_DIR} ${ACCESS_TOKEN}

done <${FILE_DIR}/ewas-sum-stats/studies-to-add.txt