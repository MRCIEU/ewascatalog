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

LIVE_DIR=${OUT_DIR}/website
mkdir -p ${LIVE_DIR}

bash ${REPO_DIR}/website/scripts/stop.sh
sleep 2

bash ${REPO_DIR}/website/scripts/update.sh ${CONFIG}

echo "Starting website ..."
CWD=$(pwd)
cd ${LIVE_DIR}
apptainer instance start \
    --bind ${DATA_DIR}:/data \
    --bind ${LIVE_DIR}/django:/django \
    --env-file ${SETTINGS} \
    ${LIVE_DIR}/container.sif \
    app_website_instance
cd ${CWD}

