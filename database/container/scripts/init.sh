#!/bin/bash

set -e

: "${DATABASE_HOST:?database hostname missing}"
: "${DATABASE_NAME:?database identifier missing}"
: "${DATABASE_USER:?database user name missing}"
: "${DATABASE_PASSWORD:?database password missing}"
: "${DATABASE_PORT:?database port missing}"
: "${MYSQL_ROOT_PASSWORD:?database root password missing}"
  
if [ ! -d "/data/mysql/mysql" ]; then
    rm -f /tmp/mysql.sock /tmp/mysql.sock.lock
    rm -f /tmp/mysqlx.sock /tmp/mysqlx.sock.lock
    mysqld --initialize-insecure --user=mysql
    mysqld --user=mysql &
    MYSQL_PID=$!
    sleep 10
    mysql --local-infile=1 -u root <<EOF
    	$(envsubst < /scripts/init.sql)
EOF
    kill $MYSQL_PID
    wait $MYSQL_PID
fi
