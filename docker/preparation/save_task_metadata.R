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

# Automatic Exploration of Machine Learning Experiments on OpenML
# Daniel Kühn, Philipp Probst, Janek Thomas, Bernd Bischl
# https://arxiv.org/pdf/1806.10961.pdf
# table 3
paper_data_ids  = c(3, 31, 37, 44, 50, 151, 312, 333, 334, 335, 1036, 1038, 1043, 1046, 1049, 1050, 1063, 1067, 1068, 1120, 1461, 1462, 1464, 1467, 1471, 1479, 1480, 1485, 1486, 1487, 1489, 1494, 1504, 1510, 1570, 4134, 4534)

result$data_in_paper = result$data %in% paper_data_ids

# Save to file
saveRDS(result, file = "../omlbotlookup/app/task_metadata.Rds")
