library("RMySQL")

# Declare database credentials
mysql_username = "root"
mysql_password = ""
mysql_dbname_from = "openml_native"
mysql_host = "127.0.0.1"

# Open database connection
con <- dbConnect(MySQL(), user = mysql_username, password = mysql_password, dbname = mysql_dbname_from, host = mysql_host)

# Get raw data in wrong format
sql.exp = "SELECT t1.data, t1.quality, t1.value, t2.task_id FROM
(SELECT data, quality, value FROM data_quality WHERE quality IN ('NumberOfFeatures', 'NumberOfInstances', 'NumberOfClasses', 'NumberOfNumericFeatures', 'NumberOfSymbolicFeatures', 'MajorityClassPercentage', 'DecisionStumpErrRate')) t1
INNER JOIN
(SELECT task_id, value AS data FROM task_inputs WHERE input = 'source_data' AND task_id IN (SELECT DISTINCT task_id FROM run WHERE uploader = 2702)) t2
ON t1.data = t2.data;"

result = dbGetQuery(con, sql.exp)
result = tidyr::spread(result, key = quality, value = value)
result = dplyr::rename(result, features = "NumberOfFeatures", instances = "NumberOfInstances")
for (j in seq_len(ncol(result))) {
  result[[j]] = type.convert(result[[j]])
  if (is.numeric(result[[j]]) && all(result[[j]]%%1 == 0)) {
    result[[j]] = as.integer(result[[j]])
  }
}

# Save to file
saveRDS(result, file = "../omlbotlookup/app/task_metadata.Rds")
