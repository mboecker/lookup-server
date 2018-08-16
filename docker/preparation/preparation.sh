#!/bin/bash

# This skript
# 1. checks if a local snapshot exists
# 2. if not it checks if the snapshot file exists in current dir
# 3. if not it will download it
# 4. and load it into mysql
# 5. after everything is in the local mysql db it will reduce it to openml_exporting
# 6. generate parameter_ranges.Rds

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
url=https://www.openml.org/downloads/ExpDB_SNAPSHOT.sql.gz
file=ExpDB_SNAPSHOT.sql.gz
database=openml_native_full

# 1. check if DB exists
RESULT=`mysql -e "SHOW DATABASES" | grep $database`
if [ "$RESULT" == "$database" ]; then
  echo "Database already exist. Skip importing dump."
else
  echo "Database does not exist. Importing dump now..."
  # 2+3. download file
  if [ ! -f $file ]; then
    echo "File $file not found! We will download it..."
    # axel can download a bit faster with multiple connections
    if command -v axel >/dev/null; then
      axel -n 4 -o $file $url 
    else
      wget $url -O $file
    fi
  fi
  # 4. load it into mysql
  echo "Importing dump into mysql"
  mysql -e "CREATE DATABASE $database;"
  if command -v pv >/dev/null; then
    # pv can give us a fancy progress bar
    pv $file | gunzip | mysql -u root $database
  else
    zcat $file | mysql -u root $database
  fi
fi

# 5.#
echo "Preparing database for exporting small subset"
mysql -u root < mysql_export_task3.sql
echo "Preparing database for exporting"
mysql -u root < mysql_export.sql

# 6.
echo "Prepare Parameter Ranges..."
Rscript prepare_parameter_ranges.R

# 7. 
echo "Reformat db..."
Rscript prepare_parameter_ranges.R

# 8.
echo "Done preparing. Exporting compressed data to reduced.sql.gz"
mysqldump -u root -p --single-transaction openml_exporting | gzip > reduced.sql.gz