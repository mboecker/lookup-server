#!/bin/sh
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
docker run -d --volume=$PWD/mysqldata:/mysqldata -p 8746:8746 --name=$USER-omlbotlookup omlbotlookup:$USER
