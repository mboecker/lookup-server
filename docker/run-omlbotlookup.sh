#!/bin/bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
echo "Run docker..."
docker run -itd -p 8746:8746 --name=$USER-omlbotlookup omlbotlookup:$USER
echo "Start mysql on container..."
docker exec -i $USER-omlbotlookup service mysql start
echo "Diag file permissions..."
docker exec -i $USER-omlbotlookup ls -al /var/log
echo "Dump err.log"
docker exec -i $USER-omlbotlookup cat /var/log/mysql/error.log
echo "Create database on container..."
echo "CREATE DATABASE IF NOT EXISTS openml;" |  docker exec -i $USER-omlbotlookup mysql
echo "Dump snapshot to database..."
gzip -cd mysqldata/database.sql.gz | docker exec -i $USER-omlbotlookup mysql openml
docker exec -d $USER-omlbotlookup bash -c "cd && /usr/bin/Rscript rest_server.R"
