library(devtools)
load_all()
startOmlTuneServer()

lrn.str = "classif.glmnet"
par.set = getParamSetForOmlLearner(lrn.str)
par.set
task.id = 3
param = list(algo = lrn.str, task = 3, alpha = 0.5, lambda = 0)
httr.res = GET("http://localhost:8746", query = param, httr::accept_json())
res = httr::content(httr.res)
res
stopOmlTuneServer()
