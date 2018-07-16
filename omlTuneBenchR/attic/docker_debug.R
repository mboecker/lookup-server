algo_id = "mlr.classif.ranger"
task_id = 3
par_vals = list(num.trees = 903L, replace = TRUE, sample.fraction = 0.561601456510834, 
    mtry = 0.706765820272267, respect.unordered.factors = TRUE, 
    min.node.size = 0.332096129655838)
parameter_names = names(par_vals)

table.backup = table

resultd = table.backup
for (i in parameter_names) {
  resultd[[i]] = type.convert(resultd[[i]])
}
table = resultd

task = 3
algo = "classif.ranger"
parameters = list(num.trees = 1571L, replace = FALSE, sample.fraction = 0.261198015045375, 
    mtry = 0.486850310349837, respect.unordered.factors = FALSE, 
    min.node.size = 0.298237264622003)
task_id = task
par_vals = parameters