#!/bin/bash

set -e

DIR=$1

if [ -z "$DIR" ]; then
	echo "Usage: $0 <study-dir>"
	exit 1
fi

: "${DATABASE_NAME:?database identifier missing}"
: "${DATABASE_USER:?database user name missing}"
: "${DATABASE_PASSWORD:?database password missing}"

. /opt/venv/bin/activate
python /scripts/prep.py $DIR
