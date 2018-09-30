# How-To

* Prepare full OpenML database in MySQL, the database name should be "openml"
* Run `./reduce.sh`
* This will create a reduced.sql.gz, which is the only data the container needs.
* Import this into the container.

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
