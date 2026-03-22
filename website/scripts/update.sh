#!/bin/bash

set -e

CONFIG=$1

if [ -z "$CONFIG" ]; then
	echo "Usage: $0 <config-file>"
	exit 1
fi

CONFIG=$(realpath "$CONFIG")

source $CONFIG

OUT_DIR=$(realpath "$OUT_DIR")
REPO_DIR=$(realpath "$REPO_DIR")
DATA_DIR=$(realpath "$DATA_DIR")

echo "Copying over website files ..."
LIVE_DIR=${OUT_DIR}/website
mkdir -p ${LIVE_DIR}
rsync -av ${REPO_DIR}/website/container/ ${LIVE_DIR}/

echo "Copying over download files ... "
DOWNLOAD_DIR=${LIVE_DIR}/django/catalog/static/docs/
mkdir -p ${DOWNLOAD_DIR}
cp ${DATA_DIR}/studies/studies.txt.gz ${DOWNLOAD_DIR}/ewascatalog-studies.txt.gz
cp ${DATA_DIR}/studies/results.txt.gz ${DOWNLOAD_DIR}/ewascatalog-results.txt.gz

