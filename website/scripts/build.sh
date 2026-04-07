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

LIVE_DIR=${OUT_DIR}/website
mkdir -p ${LIVE_DIR}

bash ${REPO_DIR}/website/scripts/update.sh ${CONFIG}

mkdir -p ${LIVE_DIR}/django/catalog/static/tmp
if [ ! -e "${LIVE_DIR}/website.sif" ]; then
    echo "Building website container..."
    cd ${LIVE_DIR}; apptainer build website.sif website.def
fi
