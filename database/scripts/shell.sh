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

LIVE_DIR=${OUT_DIR}/database

CWD=$(pwd)
cd ${LIVE_DIR}

echo "To login to the database: mysql -u \${DATABASE_USER} -p\${DATABASE_PASSWORD} \${DATABASE_NAME}"

apptainer exec \
    --env-file ${SETTINGS} \
    instance://app_db_instance \
    /bin/bash




