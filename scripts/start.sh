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

bash ${REPO_DIR}/database/scripts/start.sh ${CONFIG}
bash ${REPO_DIR}/website/scripts/start.sh ${CONFIG}
bash ${REPO_DIR}/webserver/scripts/start.sh ${CONFIG}

echo "Running instances:"
apptainer instance list

