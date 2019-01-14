# How-To

* Have a local mysql db running with a passwordless root
  * Changing this would have to be done in various files in this directory.
* Run `./preparation.sh`
  * Downloads nightly OML database snapshot
  * Loads snapshot into local MySQL DB
  * Outputs reduced SQL DB Dump to `../omlbotlookup/mysqldata/reduced.sql.gz`
  * Outputs additional Metadata into `../omlbotlookup/app/*.rds` files

# Debugging Version of the data: Task 3

In case you want to debug the preparation step or the container, we also include a way to prepare a smaller version of the database. This only includes task 3. This is created by changing one line in "preparation.sh". Change line 62 from

```
$mysql_command $database < mysql_export.sql
```

to

```
$mysql_command $database < mysql_export_task3.sql
```

This will stop generating the full dump but instead reformat the database to only include task 3.
