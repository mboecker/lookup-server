#!/bin/bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
zcat mysqldata/reduced_task3.sql.gz | ./import-data.sh
