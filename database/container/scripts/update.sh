#!/bin/bash

set -e

: "${DATABASE_HOST:?database hostname missing}"
: "${DATABASE_NAME:?database identifier missing}"
: "${DATABASE_USER:?database user name missing}"
: "${DATABASE_PASSWORD:?database password missing}"
: "${DATABASE_PORT:?database port missing}"

. /opt/venv/bin/activate
python /scripts/update.py /data/inputs/studies /scripts/add-counts.sql
