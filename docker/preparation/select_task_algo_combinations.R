library("RMySQL")

# Declare database credentials
mysql_username = "root"
mysql_password = ""
mysql_dbname = "openml_reformatted"
mysql_host = "127.0.0.1"

# Delete the cache after 120 seconds
cache.timeout = 120

# Open database connection
con <- dbConnect(MySQL(), user = mysql_username, password = mysql_password, dbname = mysql_dbname, host = mysql_host)

get_task_ids_for_algo = function(algo) {
  sql.exp = sprintf("SELECT DISTINCT task_id FROM `%s`;", algo)
  dbGetQuery(con, sql.exp)$task_id
}

get_algos = function() {
  sql.exp = "SHOW TABLES"
  r = dbGetQuery(con, sql.exp)
  r[[1]]
}

algo_names = get_algos()
availiable_tasks = lapply(algo_names, get_task_ids_for_algo)
names(availiable_tasks) = algo_names

saveRDS(availiable_tasks, file = "../../omlTuneBenchR/tests/availiable_tasks.Rds")
