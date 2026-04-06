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
	echo "Error: '$DIR/studies' does not exist."
	exit 1
fi

source ${CONFIG}

SETTINGS=$(realpath "$SETTINGS")

echo "Preparing to REMOVE studies in ${DIR}/studies.txt ..."

apptainer exec \
    --env-file ${SETTINGS} \
    --pwd ${DIR} \
    instance://app_db_instance \
    bash /scripts/remove.sh ${DIR}
