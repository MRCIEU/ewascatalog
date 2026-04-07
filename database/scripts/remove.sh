#!/bin/bash

set -e

if [ "$#" -lt 2 ]; then
	echo "Usage: $0 <config-file> <study-dir>"
	exit 1
fi

CONFIG=$1
DIR=$2

if [ ! -f "$CONFIG" ]; then
	echo "Error: config file '$CONFIG' does not exist."
	exit 1
fi

if [ ! -d "$DIR" ]; then
	echo "Error: study directory '$DIR' does not exist."
	exit 1
fi


CONFIG=$(realpath "$CONFIG")
source ${CONFIG}

OUT_DIR=$(realpath "$OUT_DIR")
SETTINGS=$(realpath "$SETTINGS")

LIVE_DIR=${OUT_DIR}/database

echo "Preparing to REMOVE studies in ${DIR}/studies.txt ..."

apptainer exec \
    --env-file ${SETTINGS} \
    --pwd ${LIVE_DIR} \
    instance://app_db_instance \
    bash /scripts/remove.sh /data/${DIR}
