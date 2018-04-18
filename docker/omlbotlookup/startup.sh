#!/bin/bash

# In a construct like "a | b", this causes "a | b" to fail, if a failed:
set -o pipefail

# Start the database service.
service mysql start

if [ ! -f /root/already_loaded.lockfile ]; then
	# Create an empty database.
	echo "CREATE DATABASE IF NOT EXISTS openml;" | mysql

	echo "Loading data..."
	# Load the data from an external source.
	gzip -cd mysqldata/database.sql.gz | mysql openml

	# Check if loading succeded.
	if [ $? -eq 0 ]; then
		echo "Data loading finished."
		touch /root/already_loaded.lockfile
	else
		echo "Failed to load data!"
		exit 1
	fi
fi

# Start the REST server.
cd /root/
/usr/bin/Rscript rest_server.R
echo "Stopped working."
