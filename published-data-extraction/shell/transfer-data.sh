#!/bin/bash

# -------------------------------------------------------
# Script copies data to or from synced sharepoint area
# -------------------------------------------------------

to_or_from=$1
date=$2

synced_dir="/Users/tb13101/University of Bristol/grp-ewas-catalog - data-deposit"
unsynced_dir="/Users/tb13101/Desktop/projects/phd/ewas_catalog/local-webapp/ewascatalog/published-data-extraction/recruits-data"

if [[ ! -d "${synced_dir}" ]]; then
	echo "The sharepoint directory synced to a local space was not found"
	exit 126
elif [[ ! -d "${unsynced_dir}" ]]; then
	echo "The local space (not synced to the sharepoint website) was not found"
	exit 126
fi

## checking specifications

if [[  -z "$date" ]]; then
	echo "ERROR: please provide a date"
	exit exit 126
fi

if [[ "$to_or_from" == "to" ]]; then
	echo "Copying papers-to-add data from ${unsynced_dir} to ${synced_dir}"
	while read recruit; do
		echo ${recruit}
		mkdir -p "${synced_dir}/${recruit}/${date}"
		cp "${unsynced_dir}/${recruit}/${date}/papers-to-add-${date}.xlsx" "${synced_dir}/${recruit}/${date}/"
	done <${unsynced_dir}/recruits.txt
elif [[ "$to_or_from" == "from" ]]; then
 	echo "Copying uploaded results from ${synced_dir} to ${unsynced_dir}"
 	while read recruit; do
		echo ${recruit}
		cp -R "${synced_dir}/${recruit}/${date}/" "${unsynced_dir}/${recruit}/${date}"
	done <${unsynced_dir}/recruits.txt
else
	echo "ERROR: please specify to or from"
	exit 126
fi
