#!/bin/sh
docker run -d --volume=$PWD/mysqldata:/mysqldata -p 8746:8000 --name=$USER-omlbotlookup omlbotlookup:$USER
