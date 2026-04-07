#!/bin/bash

set -e

: "${DATABASE_NAME:?database identifier missing}"
: "${DATABASE_USER:?database user name missing}"
: "${DATABASE_PASSWORD:?database password missing}"
: "${MYSQL_ROOT_PASSWORD:?root password missing}"

. /opt/venv/bin/activate
python /scripts/update.py /data/studies /scripts/add-counts.sql
