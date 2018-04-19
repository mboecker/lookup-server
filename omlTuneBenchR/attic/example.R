library(devtools)
load_all()
startOmlTuneServer()

learner.name = "classif.kknn"
task.id = 3

of = makeOmlBenchFunction(learner.name, task.id)
par.set = getParamSet(of)
x = sampleValue(par.set)
res = of(x)
res
des = generateGridDesign(par.set, 20)
res = of(as.list(des))
des$y = as.numeric(res)
plot(des$k, des$y, type = "b")

learner.name = "classif.glmnet"
of = makeOmlBenchFunction(learner.name, task.id)
par.set = getParamSet(of)
res = of(sampleValue(par.set))
res
des = generateGridDesign(par.set, 50)
des$y = apply(des, 1, of)
mdes = reshape2::melt(des, measure.vars = c("alpha", "lambda"))
library(ggplot2)
g = ggplot(des, aes(x = alpha, y = lambda, fill = y))
g + geom_tile()

stopOmlTuneServer()
