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

echo "Starting website container ..."
echo "(run a query: /opt/venv/bin/python -s /scripts/run-query.py <query>)"

apptainer exec \
    --env-file ${SETTINGS} \
    --pwd $(realpath $(pwd)) \
    instance://app_website_instance \
    /bin/bash
