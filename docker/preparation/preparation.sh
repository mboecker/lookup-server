#!/bin/bash

task3=false

while [ "$1" != "" ]; do
    case $1 in
        -t | --task3 )  task3=true
                        ;;
    esac
    shift
done

# This skript
# 1. checks if a local snapshot exists
# 2. if not it checks if the snapshot file exists in current dir
# 3. if not it will download it
# 4. and load it into mysql
# 5. after everything is in the local mysql db it will reduce it to openml_exporting
# 6. generate parameter_ranges.Rds

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
set -o pipefail
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

  # Patch .sql file to remove "key is too large" error
  if [ ! -f $filepatched ]; then
    echo "Patching file to avoid 'key is too large' error."
    if command -v pv >/dev/null; then
      pv $file | gunzip | sed -f patch.sed | gzip > $filepatched
    else
      zcat $file | sed -f patch.sed | gzip > $filepatched
    fi
  fi

  # 4. load it into mysql into $database
  echo "Importing dump into mysql"
  $mysql_command -e "CREATE DATABASE $database;"
  if command -v pv >/dev/null; then
    # pv can give us a fancy progress bar
    pv $filepatched | gunzip | $mysql_command $database
  else
    zcat $filepatched | $mysql_command $database
  fi
fi

# 5. Write only usable data from `$database` into `openml_exporting`
# TODO: only do this if database `openml_exporting` not found.
echo "Preparing database for exporting."
echo "  Shrinking..."
$mysql_command $database < sql/shrink_db.sql

echo "  Selecting..."
if [ "$task3" == "true" ]; then
  $mysql_command $database < sql/select_runs_task3.sql
else
  $mysql_command $database < sql/select_runs.sql
fi

echo "  Inserting..."
$mysql_command $database < sql/insert_run_data.sql

# 6.
echo "Prepare Parameter Ranges..."
Rscript prepare_parameter_ranges.R	

# 7. Read data from `openml_exporting`, re-format it in R and write it to `openml_reformatted`
$mysql_command -e "DROP DATABASE IF EXISTS openml_reformatted; CREATE DATABASE openml_reformatted;"
echo "Reformat db..."
Rscript prepare_db.R

# 8. Dump final reformatted database file
echo "Done preparing. Exporting compressed data to reduced.sql.gz"
if [ "$task3" == "true" ]; then
  $mysqldump_command openml_reformatted | gzip > ../mysqldata/reduced_task3.sql.gz
else
  $mysqldump_command openml_reformatted | gzip > ../mysqldata/reduced.sql.gz
fi

# 9. Save Task Metadata
Rscript save_task_metadata.R
