# debug in container
source("data_access.R")
source("helper.R")

algo = algo_id = "classif.ranger"
task = task_id = 219
ps = parameter_ranges[[algo]]
pv = sampleValue(ps)
parameters = jsonlite::toJSON(pv)

table = get_table(algo_id, task_id)




algo = algo_id = "classif.kknn"
task = task_id = 3
table = get_table(algo_id, task_id)
parameters = structure(list(k = c(8L, 12L)), row.names = c(NA, -2L), class = "data.frame", trafo = FALSE)
parameters = setDT(parameters)