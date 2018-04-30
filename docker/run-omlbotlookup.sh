#!/bin/bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
docker run -itd -p 8746:8746 --name=$USER-omlbotlookup omlbotlookup:$USER
docker exec -i $USER-omlbotlookup service mysql start
echo "CREATE DATABASE IF NOT EXISTS openml;" |  docker exec -i $USER-omlbotlookup mysql
gzip -cd mysqldata/database.sql.gz | docker exec -i $USER-omlbotlookup mysql openml
docker exec -d $USER-omlbotlookup bash -c "cd && /usr/bin/Rscript rest_server.R"
