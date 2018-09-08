library("RMySQL")

# Declare database credentials
mysql_username = "root"
mysql_password = ""
mysql_dbname_from = "openml_native"
mysql_host = "127.0.0.1"

# Open database connection
con <- dbConnect(MySQL(), user = mysql_username, password = mysql_password, dbname = mysql_dbname_to, host = mysql_host)

sql.exp = sprintf("SELECT data, quality, value FROM %s.data_quality WHERE quality='NumberOfFeatures' OR quality='NumberOfInstances'", mysql_dbname_from)
result = dbGetQuery(con, sql.exp)

data.frame(task.id = result$data, 
