library(devtools)
setwd(file.path(rprojroot::find_root(rprojroot::is_git_root), "omlTuneBenchR"))
load_all()
startOmlTuneServer()

task.id = 3
learner.name = "classif.ranger"
of = makeOmlBenchFunction(learner.name, task.id, include.extras = TRUE)
par.set = getParamSet(of)
x = sampleValue(par.set)
system.time({res = of(x)})
#do.call(rbind, attr(res, "extras"))
do.call(cbind, x)
des = generateRandomDesign(n = 6L*4L, par.set = par.set)
res = of(des)
des$y = res

library(mlrMBO)
ctrl = makeMBOControl()
ctrl = setMBOControlInfill(control = ctrl, crit = crit.cb)
ctrl = setMBOControlTermination(control = ctrl, iters = 20)
mbo.res = mbo(fun = of, design = des, control = ctrl)
mbo.res

## random search

des = generateRandomDesign(n = 1000, par.set = par.set)
res = of(des)
max(res)

stopOmlTuneServer()
