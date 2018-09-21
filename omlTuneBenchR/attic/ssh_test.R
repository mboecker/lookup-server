library(omlTuneBenchR)

system(command = "ssh -M -S omllookup-socket -fnNT -L 8746:129.217.31.62:8746 sfbclust")
on.exit({system(command = "ssh -S omllookup-socket -O exit sfbclust")})
omlTuneBenchR::connectToOmlTuneServer("http://localhost:8746")

(tasks = omlTuneBenchR::getAvailableTasks())

fun = omlTuneBenchR::makeOmlBenchFunction("classif.rpart", task.id = sample(tasks, 1), include.extras = TRUE)
ps = getParamSet(fun)
x = generateRandomDesign(n = 100, ps)
res = fun(x = x)
library(data.table)
res.dt = rbindlist(attr(res, "extras"))
res.dt$y = as.vector(res)
res.dt = cbind(res.dt, x)
# colnames(res.dt) = stringi::stri_replace_all_regex(colnames(res.dt), pattern = "^\.", replacement = "")
res.dt[.lookup.distance == max(.lookup.distance), ]
range(res.dt$minbucket)
hist(res.dt$.lookup.distance)
