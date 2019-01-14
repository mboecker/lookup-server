library("RMySQL")
library("data.table")

# Declare database credentials
mysql_username = "root"
mysql_password = ""
mysql_dbname_from = "openml_native"
mysql_host = "127.0.0.1"
rds_path = "../omlbotlookup/app/rdsdata/"

# Open database connection
con <- dbConnect(MySQL(), user = mysql_username, password = mysql_password, dbname = mysql_dbname_from, host = mysql_host)

#' Which algorithms have been run on this task?
#'
#' @param task_id This is `task_id` from the table `run` in the database.
#'
#' @return A named list, containing one enftry for each different algorithm name, and the algorithm ids for each algorithm name.
get_algos = function() {
  files = dir(rds_path, all.files = TRUE, pattern = "*\\.rds", include.dirs = FALSE)  
  files = gsub(pattern = "data_(.+)_[0-9]+\\.rds", replacement = "\\1", x = files)  
  return(unique(files))
}

# Get raw data in wrong format
sql.exp = "SELECT t1.data, t1.quality, t1.value, t2.task_id FROM
(SELECT data, quality, value FROM data_quality WHERE quality IN ('NumberOfFeatures', 'NumberOfInstances', 'NumberOfClasses', 'NumberOfNumericFeatures', 'NumberOfSymbolicFeatures', 'MajorityClassPercentage', 'DecisionStumpErrRate')) t1
RIGHT JOIN
(SELECT task_id, value AS data FROM task_inputs WHERE input = 'source_data' AND task_id IN (SELECT DISTINCT task_id FROM run WHERE uploader = 2702)) t2
ON t1.data = t2.data;"

result = dbGetQuery(con, sql.exp)
result = tidyr::spread(result, key = quality, value = value, fill = NA) #NAs can occur bcz of right join.
result = result[, !vapply(result, function(x) all(is.na(x)), logical(1))]
result = dplyr::rename(result, features = "NumberOfFeatures", instances = "NumberOfInstances")
for (j in seq_len(ncol(result))) {
  result[[j]] = type.convert(result[[j]])
  if (is.numeric(result[[j]]) && all(result[[j]]%%1 == 0, na.rm = TRUE)) {
    result[[j]] = as.integer(result[[j]])
  }
}

# dataset 1176 is deactivated and therefore some tasks (6566, 34536, 146085)

# Automatic Exploration of Machine Learning Experiments on OpenML
# Daniel Kühn, Philipp Probst, Janek Thomas, Bernd Bischl
# https://arxiv.org/pdf/1806.10961.pdf
# table 3
paper_data_ids  = c(3, 31, 37, 44, 50, 151, 312, 333, 334, 335, 1036, 1038, 1043, 1046, 1049, 1050, 1063, 1067, 1068, 1120, 1461, 1462, 1464, 1467, 1471, 1479, 1480, 1485, 1486, 1487, 1489, 1494, 1504, 1510, 1570, 4134, 4534)

result$data_in_paper = result$data %in% paper_data_ids

# Select number of runs with given algo and every task from database.
tables = lapply(get_algos(), function(algo_id) {
  files = dir(rds_path, all.files = TRUE, pattern = paste0("data_", algo_id, "_[0-9]+\\.rds"), include.dirs = FALSE)
  lapply(files, function(file) {
    table = readRDS(file.path(rds_path, file))
    n = nrow(table)
    task_id = as.numeric(regmatches(file, regexpr("[0-9]+", file)))
    data.frame(algo_id = algo_id, task_id = task_id, n = n)
  })
})
table = rbindlist(unlist(tables, recursive=FALSE))
# for each algo select the task that has the most runs (we have multiple tasks on the same data)
#table = merge(table, result[, c("task_id", "data")], by = "task_id")
#table = table[, {i = which.max(n); .SD[i,]} , by = c("data", "algo_id")]
table = tidyr::spread(table, key = "algo_id", value = "n")

result = merge(table, result, all.x = TRUE, by = c("task_id"))
setkeyv(result, "data")

# Save to file
saveRDS(result, file = "../omlbotlookup/app/task_metadata.rds")

# save for package
rda.file = dir("../omlbotlookup/app/", all.files = TRUE, pattern = "*\\.rds", include.dirs = FALSE, full.names = TRUE)
names = sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(rda.file))
objects = setNames(lapply(rda.file, readRDS), names)
do.call(save, c(as.list(names(objects)), list(file = "../../omlTuneBenchR/R/sysdata.rda", envir = as.environment(objects), compress = "bzip2")))
do.call(save, c(as.list(names(objects)), list(file = "../../omlTuneBenchRLocal/R/sysdata.rda", envir = as.environment(objects), compress = "bzip2")))
