#!/bin/sh
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
docker rmi omlbotlookup:$USER
docker build -t omlbotlookup:$USER omlbotlookup
