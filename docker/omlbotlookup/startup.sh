#!/bin/bash

# In a construct like "a | b", this causes "a | b" to fail, if a failed:
set -o pipefail

# Start the database service.
service mysql start

cat /var/log/mysql/error.log

# Create an empty database.
echo "CREATE DATABASE IF NOT EXISTS openml;" | mysql

# Start the REST server.
cd /root/
/usr/bin/Rscript rest_server.R
echo "Stopped working."
