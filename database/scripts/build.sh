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
SOCKET_DIR=$(realpath "$SOCKET_DIR")
DATA_DIR=$(realpath "$DATA_DIR")

bash ${REPO_DIR}/database/scripts/stop.sh
sleep 2

LIVE_DIR=${OUT_DIR}/database
mkdir -p ${LIVE_DIR}

## copy the database container files 
rsync -av ${REPO_DIR}/database/container/ ${LIVE_DIR}/

## build the database container
if [ ! -e "${LIVE_DIR}/database.sif" ]; then
    echo "Building database container ..."
    cd ${LIVE_DIR}; apptainer build database.sif database.def
fi

## if the database does not exist, initialize it
if [ ! -d "${LIVE_DIR}/lib/mysql" ]; then
    echo "Preparing database socket ..."
    mkdir -p ${SOCKET_DIR}
    chmod 777 ${SOCKET_DIR}
    rm -f ${SOCKET_DIR}/*
    
    echo "Initializing database ..."
    cd ${LIVE_DIR}; mkdir -p logs lib mysql-files
    params=(
        --bind ${LIVE_DIR}/lib:/var/lib/mysql                ## mysql files
	--bind ${LIVE_DIR}/mysql-files:/var/lib/mysql-files  ## mysql needs this
	--bind ${LIVE_DIR}/custom.cnf:/etc/mysql/my.cnf:ro   ## mysql config
	--bind ${LIVE_DIR}/logs:/var/log/mysql               ## mysql logs
	--bind ${LIVE_DIR}/scripts:/scripts		     ## container scripts
	--bind ${SOCKET_DIR}:/var/run/mysqld		     ## mysql socket
	--bind ${DATA_DIR}:/data			     ## EWAS data directory
	--env-file ${SETTINGS}                               ## environment variables
    )
    cd ${LIVE_DIR}; apptainer exec "${params[@]}" database.sif bash /scripts/init.sh 
fi

echo "Database initialized, preparing to update ..."
bash ${REPO_DIR}/database/scripts/start.sh ${CONFIG}
bash ${REPO_DIR}/database/scripts/update.sh ${CONFIG}
bash ${REPO_DIR}/database/scripts/stop.sh
