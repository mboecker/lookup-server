#!/bin/bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
cat | docker exec -i $USER-omlbotlookup /root/import_db.sh
