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

if [ ! -d "$DATA_DIR/$DIR" ]; then
	echo "Error: study directory '$DATA_DIR/$DIR' does not exist."
	exit 1
fi

OUT_DIR=$(realpath "$OUT_DIR")
SETTINGS=$(realpath "$SETTINGS")

LIVE_DIR=${OUT_DIR}/database

echo "Preparing studies in ${DIR} for upload ..."

apptainer exec \
    --env-file ${SETTINGS} \
    --pwd ${LIVE_DIR} \
    instance://app_db_instance \
    bash /scripts/prep.sh /data/${DIR}
