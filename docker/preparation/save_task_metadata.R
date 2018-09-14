library("RMySQL")

# Declare database credentials
mysql_username = "root"
mysql_password = ""
mysql_dbname_from = "openml_native"
mysql_host = "127.0.0.1"

# Open database connection
con <- dbConnect(MySQL(), user = mysql_username, password = mysql_password, dbname = mysql_dbname_from, host = mysql_host)

# Get raw data in wrong format
sql.exp = sprintf("SELECT data, quality, value FROM %s.data_quality WHERE quality='NumberOfFeatures' OR quality='NumberOfInstances'", mysql_dbname_from)
result = dbGetQuery(con, sql.exp)

# Re-format data
meta_data = data.frame(task.id = result$data, features = result[result$quality == "NumberOfFeatures",]$value, instances = result[result$quality == "NumberOfInstances",]$value)

# Save to file
saveRDS(meta_data, file = "../omlbotlookup/task_metadata.Rds")
