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

CWD=$(pwd)
cd ${LIVE_DIR}
mkdir -p django/catalog/static/tmp
if [ ! -e container.sif ]; then
    echo "Building website container..."
    apptainer build container.sif container.def
fi
cd ${CWD}
