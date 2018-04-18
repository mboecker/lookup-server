#!/bin/sh
docker run -it --volume=$PWD/mysqldata:/mysqldata -p 8746:8746 --name=$USER-omlbotlookup omlbotlookup:$USER
