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
REPO_DIR=$(realpath "$REPO_DIR")
DATA_DIR=$(realpath "$DATA_DIR")

bash ${REPO_DIR}/database/scripts/stop.sh
sleep 2

LIVE_DIR=${OUT_DIR}/database

echo "Starting database ..."
CWD=$(pwd)
cd ${LIVE_DIR}
apptainer instance start \
    --bind ${LIVE_DIR}/data:/data/mysql \
    --bind ${LIVE_DIR}/logs:/var/log/mysql \
    --bind ${LIVE_DIR}/run:/var/run/mysqld \
    --bind ${LIVE_DIR}/scripts:/scripts \
    --bind ${DATA_DIR}:${DATA_DIR} \
    ${LIVE_DIR}/container.sif \
    app_db_instance
cd ${CWD}

echo "Waiting for the database (10 seconds) ..."
sleep 10

