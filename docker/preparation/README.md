# How-To

* Prepare full OpenML database in MySQL, the database name should be "openml"
* Run `./reduce.sh`
* This will create a reduced.sql.gz, which is the only data the container needs.
* Import this into the container.
