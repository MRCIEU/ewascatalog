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
DATA_DIR=$(realpath "$DATA_DIR")

bash ${REPO_DIR}/database/scripts/stop.sh
sleep 2

LIVE_DIR=${OUT_DIR}/database

echo "Preparing for database update ..."
apptainer instance start \
    --bind ${LIVE_DIR}/data:/data/mysql \
    --bind ${LIVE_DIR}/logs:/var/log/mysql \
    --bind ${LIVE_DIR}/run:/var/run/mysqld \
    --bind ${LIVE_DIR}/scripts:/scripts \
    --bind ${DATA_DIR}:/data/inputs \
    ${LIVE_DIR}/container.sif \
    app_db_instance
sleep 10

echo "Updating database ..."
apptainer exec \
    --env-file ${SETTINGS} \
    instance://app_db_instance \
    bash /scripts/update.sh

echo "Restarting the database ..."
bash ${REPO_DIR}/database/scripts/stop.sh
sleep 10
bash ${REPO_DIR}/database/scripts/start.sh ${CONFIG}

