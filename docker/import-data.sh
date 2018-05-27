#!/bin/bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
docker exec -i $USER-omlbotlookup /root/wait_for_mysqld.sh > /dev/null < /dev/null
cat | docker exec -i $USER-omlbotlookup /root/import_db.sh
