#!/bin/bash

set -e

if [ "$#" -lt 2 ]; then
	echo "Usage: $0 <config-file> <study-dir>"
	exit 1
fi

CONFIG=$1
DIR=$2

CONFIG=$(realpath "$CONFIG")
DIR=$(realpath "$DIR")

if [ ! -f "$CONFIG" ]; then
	echo "Error: config file '$CONFIG' does not exist."
	exit 1
fi

if [ ! -f "$DIR/studies.txt" ]; then
	echo "Error: '$DIR/studies.txt' does not exist."
	exit 1
fi

source ${CONFIG}
REPO_DIR=$(realpath "$REPO_DIR")

bash ${REPO_DIR}/database/scripts/remove.sh ${CONFIG} ${DIR}
