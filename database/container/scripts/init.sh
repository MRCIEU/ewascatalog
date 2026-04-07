#!/bin/bash

set -e

: "${DATABASE_NAME:?database identifier missing}"
: "${DATABASE_USER:?database user name missing}"
: "${DATABASE_PASSWORD:?database password missing}"
: "${MYSQL_ROOT_PASSWORD:?database root password missing}"
  
mysqld --initialize-insecure --user=mysql
mysqld --user=mysql &
MYSQL_PID=$!
sleep 10
mysql --local-infile=1 -u root <<EOF
    $(envsubst < /scripts/init.sql)
EOF

kill $MYSQL_PID
wait $MYSQL_PID
