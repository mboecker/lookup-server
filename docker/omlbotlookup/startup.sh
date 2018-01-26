# Start the database service.
service mysql start

# Create the necessary tables.
echo "CREATE DATABASE IF NOT EXISTS openml;" | mysql

# Load the data from an external source.
#mysql openml < /mysqldata/ExpDB_SNAPSHOT.sql
echo "Data loading finished."

# Start the REST server.
cd /root/
/usr/bin/Rscript rest_server.R
echo "Stopped working."
