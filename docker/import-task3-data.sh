#!/bin/bash
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
file=mysqldata/reduced_task3.sql.gz
if [ ! -f $file ]; then
    echo "File $file not found! We will download it."
    wget https://www.statistik.tu-dortmund.de/~richter/reduced_task3.sql.gz -O $file
fi
zcat $file | ./import-data.sh
