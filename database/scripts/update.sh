#!/bin/bash

set -e

CONFIG=$1

if [ -z "$CONFIG" ]; then
	echo "Usage: $0 <config-file>"
	exit 1
fi

CONFIG=$(realpath "$CONFIG")

source ${CONFIG}
OUT_DIR=$(realpath "$OUT_DIR")
SETTINGS=$(realpath "$SETTINGS")

LIVE_DIR=${OUT_DIR}/database

echo "Updating database ..."

apptainer exec \
    --env-file ${SETTINGS} \
    --pwd ${LIVE_DIR} \
    instance://app_db_instance \
    bash /scripts/update.sh 
