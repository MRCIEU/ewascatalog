#!/bin/bash

set -e

apptainer instance stop app_db_instance &>/dev/null || true

rm -f /tmp/mysql.sock /tmp/mysql.sock.lock
rm -f /tmp/mysqlx.sock /tmp/mysqlx.sock.lock
