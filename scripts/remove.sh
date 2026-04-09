#!/bin/bash

set -e

if [ "$#" -lt 2 ]; then
	echo "Usage: $0 <config-file> <study-dir>"
	exit 1
fi

CONFIG=$1
DIR=$2

CONFIG=$(realpath "$CONFIG")
source ${CONFIG}

DATA_DIR=$(realpath "$DATA_DIR")

if [ ! -f "$DATA_DIR/$DIR/studies.txt" ]; then
	echo "Error: '$DATA_DIR/$DIR/studies.txt' does not exist."
	exit 1
fi

REPO_DIR=$(realpath "$REPO_DIR")
bash ${REPO_DIR}/database/scripts/remove.sh ${CONFIG} ${DIR}
