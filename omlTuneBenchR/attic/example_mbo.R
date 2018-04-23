library(devtools)
load_all()
startOmlTuneServer()

task.id = 3
learner.name = "classif.ranger"
of = makeOmlBenchFunction(learner.name, task.id)
par.set = getParamSet(of)
x = sampleValue(par.set)
res = of(x)
do.call(rbind, attr(res, "extras"))
do.call(cbind, x)
des = generateGridDesign(par.set, 100)
res = of(des)
des$y = as.numeric(res)
des$distance = purrr::map_dbl(attr(res, "extras"), "distances")
mdes = reshape2::melt(des, measure.vars = c("alpha", "lambda"))
library(ggplot2)
g = ggplot(des, aes(x = alpha, y = lambda, fill = distance))
g + geom_tile()

stopOmlTuneServer()
