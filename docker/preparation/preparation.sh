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
mysql_command="mysql -u root"
mysqldump_command="mysqldump -u root --single-transaction"
url=https://www.openml.org/downloads/ExpDB_SNAPSHOT.sql.gz
file=ExpDB_SNAPSHOT.sql.gz
filepatched=ExpDB_SNAPSHOT_patched.sql.gz
database=openml_native

# 1. check if DB exists
RESULT=`$mysql_command -e "SHOW DATABASES" | grep $database`
if [ "$RESULT" == "$database" ]; then
  echo "Database already exist. Skip importing dump."
else
  echo "Database does not exist. Importing dump now..."
  # 2+3. download file
  if [ ! -f $file ] && [ ! -f $filepatched ]; then
    echo "File $file not found! We will download it..."
    # axel can download a bit faster with multiple connections
    if command -v axel >/dev/null; then
      axel -a -n 4 -o $file $url 
    else
      wget $url -O $file
    fi
  fi

  if [ ! -f $filepatched ]; then
    echo "Patching file to avoid 'key is too large' error."
    pv $file | gzip -d | sed --expression="s/ENGINE/ROW_FORMAT=DYNAMIC &/" | gzip > $filepatched
  fi

  # 4. load it into mysql into $database
  echo "Importing dump into mysql"
  $mysql_command -e "CREATE DATABASE $database;"
  if command -v pv >/dev/null; then
    # pv can give us a fancy progress bar
    pv $file | gunzip | $mysql_command $database
  else
    zcat $file | $mysql_command $database
  fi
fi

# 5. Write only usable data from `$database` into `openml_exporting`
echo "Preparing database for exporting"
$mysql_command < mysql_export.sql

# 6.
echo "Prepare Parameter Ranges..."
Rscript prepare_parameter_ranges.R	

# 7. Read data from `openml_exporting`, re-format it in R and write it to `openml_reformatted`
$mysql_command -e "DROP DATABASE IF EXISTS openml_reformatted; CREATE DATABASE openml_reformatted;"
echo "Reformat db..."
Rscript prepare_db.R

# 8. Dump final reformatted database file
echo "Done preparing. Exporting compressed data to reformatted.sql.gz"
$mysqldump_command openml_reformatted | gzip > reformatted.sql.gz
