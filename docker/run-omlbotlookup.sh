#!/bin/sh
docker run -i --volume=$PWD/mysqldata:/mysqldata -p 8746:8000 --name=$USER-omlbotlookup omlbotlookup:$USER
