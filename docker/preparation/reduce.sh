#!/bin/bash
echo "Preparing database for exporting"
mysql -u root < mysql_export.sql
echo "Done preparing. Exporting compressed data to reduced.sql.gz"
mysqldump -u root --single-transaction openml_exporting | gzip > reduced.sql.gz
