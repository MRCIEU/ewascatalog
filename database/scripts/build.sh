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

mkdir -p ${LIVE_DIR}

## copy the database container files 
rsync -av ${REPO_DIR}/database/container/ ${LIVE_DIR}/


CWD=$(pwd)
cd ${LIVE_DIR}

## build the database container 
#rm -rf run data logs
mkdir -p run data logs
if [ ! -e container.sif ]; then
    echo "Building database container ..."
    apptainer build container.sif container.def
fi

## if the database does not exist, initialize it
if [ ! -d "${LIVE_DIR}/data/mysql" ]; then
    echo "Initializing database ..."
    apptainer exec \
    --bind ${LIVE_DIR}/data:/data/mysql \
    --bind ${LIVE_DIR}/logs:/var/log/mysql \
    --bind ${LIVE_DIR}/run:/var/run/mysqld \
    --bind ${LIVE_DIR}/scripts:/scripts \
    --bind ${DATA_DIR}:/data/inputs \
    --env-file ${SETTINGS} \
    ${LIVE_DIR}/container.sif \
    bash /scripts/init.sh
fi

cd ${CWD}

## populate the database 
bash ${REPO_DIR}/database/scripts/update.sh ${CONFIG}

