library("RMySQL")

# Declare database credentials
mysql_username = "root"
mysql_password = ""
mysql_dbname_from = "openml_native"
mysql_host = "127.0.0.1"

# Open database connection
con <- dbConnect(MySQL(), user = mysql_username, password = mysql_password, dbname = mysql_dbname_from, host = mysql_host)

# Get raw data in wrong format
sql.exp = sprintf("SELECT data, quality, value FROM %s.data_quality WHERE quality='NumberOfFeatures' OR quality='NumberOfInstances' ORDER BY `data`", mysql_dbname_from)
result = dbGetQuery(con, sql.exp)

# Re-format data
meta_data = data.frame(task_id = unique(result$data))
meta_data$features = result[result$quality == "NumberOfFeatures", c("value")]
meta_data$instances = result[result$quality == "NumberOfInstances", c("value")]

# Save to file
saveRDS(meta_data, file = "../omlbotlookup/app/task_metadata.Rds")
