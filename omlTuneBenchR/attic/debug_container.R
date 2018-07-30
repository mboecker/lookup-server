# debug in container
source("data_access.R")

algo = algo_id = "classif.svm"
task = task_id = 3
table = get_table(algo_id, task_id)
parameters = structure(list(kernel = structure(c(2L, 3L, 2L), .Label = c("linear", 
"polynomial", "radial"), class = "factor"), cost = c(5.78712463378906, 
3.85463112965226, -5.10405445937067), gamma = c(NA, -0.447607557289302, 
NA), degree = c(3L, NA, 2L)), row.names = c(NA, -3L), class = "data.frame", trafo = FALSE)

