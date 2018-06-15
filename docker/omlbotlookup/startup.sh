#!/bin/bash

# In a construct like "a | b", this causes "a | b" to fail, if a failed:
set -o pipefail

# Own the mysql (this is a workaround for travis)
chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

# Start the database service.
service mysql start

# Create an empty database.
echo "CREATE DATABASE IF NOT EXISTS openml;" | mysql

# Start the REST server.
cd /root/
/usr/bin/Rscript rest_server.R
echo "Stopped working."
