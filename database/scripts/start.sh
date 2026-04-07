#!/bin/bash

set -e

CONFIG=$1

if [ -z "$CONFIG" ]; then
	echo "Usage: $0 <config-file>"
	exit 1
fi

CONFIG=$(realpath "$CONFIG")

source ${CONFIG}

OUT_DIR=$(realpath "$OUT_DIR")
REPO_DIR=$(realpath "$REPO_DIR")
DATA_DIR=$(realpath "$DATA_DIR")
SOCKET_DIR=$(realpath "$SOCKET_DIR")

bash ${REPO_DIR}/database/scripts/stop.sh
sleep 2

LIVE_DIR=${OUT_DIR}/database

CWD=$(realpath $(pwd))

echo "Preparing database socket ..."
mkdir -p ${SOCKET_DIR}
chmod 777 ${SOCKET_DIR}
rm -rf ${SOCKET_DIR}/*

echo "Starting database container ..."
cd ${LIVE_DIR}; mkdir -p logs lib mysql-files
cd ${LIVE_DIR}; apptainer instance start \
      --bind ${LIVE_DIR}/lib:/var/lib/mysql \
      --bind ${LIVE_DIR}/mysql-files:/var/lib/mysql-files \
      --bind ${LIVE_DIR}/custom.cnf:/etc/mysql/my.cnf:ro \
      --bind ${LIVE_DIR}/logs:/var/log/mysql \
      --bind ${LIVE_DIR}/scripts:/scripts \
      --bind ${SOCKET_DIR}:/var/run/mysqld \
      --bind ${DATA_DIR}:/data \
      --bind ${CWD}:/cwd \
    ${LIVE_DIR}/database.sif \
    app_db_instance

echo "Waiting for the database (10 seconds) ..."
sleep 10

