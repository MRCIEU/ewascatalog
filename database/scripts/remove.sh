#!/bin/bash

set -e

if [ "$#" -lt 2 ]; then
	echo "Usage: $0 <config-file> <study-dir>"
	exit 1
fi

CONFIG=$1
DIR=$2

CONFIG=$(realpath "$CONFIG")
source ${CONFIG}

DATA_DIR=$(realpath "$DATA_DIR")

if [ ! -f "$DATA_DIR/$DIR/studies.txt" ]; then
	echo "Error: '$DATA_DIR/$DIR/studies.txt' does not exist."
	exit 1
fi

OUT_DIR=$(realpath "$OUT_DIR")
SETTINGS=$(realpath "$SETTINGS")

LIVE_DIR=${OUT_DIR}/database

echo "Preparing to REMOVE studies in ${DIR}/studies.txt ..."

apptainer exec \
    --env-file ${SETTINGS} \
    --pwd ${LIVE_DIR} \
    instance://app_db_instance \
    bash /scripts/remove.sh /data/${DIR}
