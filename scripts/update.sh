#!/bin/bash

set -e

CONFIG=$1

if [ -z "$CONFIG" ]; then
	echo "Usage: $0 <config-file>"
	exit 1
fi

CONFIG=$(realpath "$CONFIG")
source ${CONFIG}

REPO_DIR=$(realpath "$REPO_DIR")
OUT_DIR=$(realpath "$OUT_DIR")
DATA_DIR=$(realpath "$DATA_DIR")

mkdir -p ${OUT_DIR}

## add new data, if any, to the database
bash ${REPO_DIR}/database/scripts/update.sh ${CONFIG}

## update the website (particularly with new download files)
bash ${REPO_DIR}/website/scripts/update.sh ${CONFIG}
