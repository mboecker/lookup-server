#!/bin/bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
zcat mysqldata/reduced.sql.gz | ./import_data.sh
