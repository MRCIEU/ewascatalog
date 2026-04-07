#!/bin/bash

set -e

CONFIG=$1

if [ -z "$CONFIG" ]; then
	echo "Usage: $0 <config-file>"
	exit 1
fi

CONFIG=$(realpath "$CONFIG")

source $CONFIG

SETTINGS=$(realpath "$SETTINGS")
OUT_DIR=$(realpath "$OUT_DIR")
REPO_DIR=$(realpath "$REPO_DIR")
DATA_DIR=$(realpath "$DATA_DIR")
SOCKET_DIR=$(realpath "$SOCKET_DIR")

LIVE_DIR=${OUT_DIR}/website
mkdir -p ${LIVE_DIR}

bash ${REPO_DIR}/website/scripts/stop.sh
sleep 2

bash ${REPO_DIR}/website/scripts/update.sh ${CONFIG}

echo "Starting website ..."
mkdir -p ${LIVE_DIR}/logs
cd ${LIVE_DIR}; apptainer instance start \
    --bind ${SOCKET_DIR}:/var/run/mysql-shared \
    --bind ${DATA_DIR}:/data \
    --bind ${LIVE_DIR}/django:/django \
    --bind ${LIVE_DIR}/logs:/app/logs/ \
    --bind ${LIVE_DIR}/scripts:/scripts \
    --env-file ${SETTINGS} \
    ${LIVE_DIR}/website.sif \
    app_website_instance

