# Start the database service.
service mysql start

if [ ! -f /root/already_loaded.lockfile ]; then
	# Create the necessary tables.
	echo "CREATE DATABASE IF NOT EXISTS openml;" | mysql

	echo "Loading data..."
	# Load the data from an external source.
  gzip -cd mysqldata/database.sql.gz | mysql openml
	echo "Data loading finished."

	touch /root/already_loaded.lockfile
fi

# Start the REST server.
cd /root/
/usr/bin/Rscript rest_server.R
echo "Stopped working."
