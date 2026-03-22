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

mkdir -p ${OUT_DIR}

bash ${REPO_DIR}/database/scripts/build.sh ${CONFIG}
bash ${REPO_DIR}/website/scripts/build.sh ${CONFIG}
bash ${REPO_DIR}/webserver/scripts/build.sh ${CONFIG}
