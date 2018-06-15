#!/bin/bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
docker run -d -p 8746:8746 --name=$USER-omlbotlookup omlbotlookup:$USER
