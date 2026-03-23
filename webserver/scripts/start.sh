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

bash $REPO_DIR/webserver/scripts/stop.sh
sleep 2

LIVE_DIR=${OUT_DIR}/webserver

echo "Starting webserver ..."
CWD=$(pwd)
cd ${LIVE_DIR}
apptainer instance start \
    --bind ${LIVE_DIR}/logs:/var/log/nginx \
    --bind ${LIVE_DIR}/cache:/var/cache/nginx \
    --bind ${LIVE_DIR}/run:/var/run \
    --bind ${OUT_DIR}/website/django/catalog/static:/app/static:ro \
    --bind ${LIVE_DIR}/nginx.conf:/etc/nginx/nginx.conf \
    ${LIVE_DIR}/container.sif \
    app_webserver_instance
cd ${CWD}
