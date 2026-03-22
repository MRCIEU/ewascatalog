#!/bin/bash

set -e

CONFIG=$1

if [ -z "$CONFIG" ]; then
	echo "Usage: $0 <config-file>"
	exit 1
fi

CONFIG=$(realpath "$CONFIG")
source ${CONFIG}

SETTINGS=$(realpath "$SETTINGS")

OUT_DIR=$(realpath "$OUT_DIR")
REPO_DIR=$(realpath "$REPO_DIR")

bash ${REPO_DIR}/webserver/scripts/stop.sh
sleep 2

LIVE_DIR=${OUT_DIR}/webserver
mkdir -p ${LIVE_DIR}
rsync -av ${REPO_DIR}/webserver/container/ ${LIVE_DIR}/

source ${SETTINGS}
export WEBSITE_HOST
export WEBSITE_PORT
export WEBSERVER_NAME
export WEBSERVER_PORT
envsubst '${WEBSITE_HOST},${WEBSITE_PORT},${WEBSERVER_NAME},${WEBSERVER_PORT}' \
	 < ${REPO_DIR}/webserver/container/nginx.conf \
	 > ${LIVE_DIR}/nginx.conf 

CWD=$(pwd)
cd ${LIVE_DIR}
mkdir -p logs cache run
if [ ! -e container.sif ]; then
    echo "Building webserver container..."
    apptainer build --ignore-fakeroot-command container.sif container.def
fi
cd ${CWD}
