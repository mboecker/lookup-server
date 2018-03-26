library(devtools)
load_all()
startOmlTuneServer()

lrn.str = "classif.kknn"
task.id = 3

of = makeOmlBenchFunction(lrn.str, task.id)
par.set = getParamSet(of)
res = of(sampleValue(par.set))
des = generateGridDesign(par.set, 20)
des$y = apply(des, 1, of)
plot(des$k, des$y, type = "b")

lrn.str = "classif.glmnet"
of = makeOmlBenchFunction(lrn.str, task.id)
par.set = getParamSet(of)
res = of(sampleValue(par.set))
des = generateGridDesign(par.set, 10)
des$y = apply(des, 1, of)
mdes = reshape2::melt(des, measure.vars = c("alpha", "lambda"))
library(ggplot2)
g = ggplot(des, aes(x = alpha, y = lambda, fill = y))
g + geom_tile()

stopOmlTuneServer()
