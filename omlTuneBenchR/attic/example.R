library(devtools)
load_all()
startOmlTuneServer()

learner.name = "classif.kknn"
task.id = 3

of = makeOmlBenchFunction(learner.name, task.id, include.extras = TRUE)
par.set = getParamSet(of)
set.seed(1)
x2 = generateRandomDesign(2, par.set)
res = of(x2)
res
des = generateGridDesign(par.set, 20)
res = of(des)
des$y = as.numeric(res)
plot(des$k, des$y, type = "b")

learner.name = "classif.glmnet"
of = makeOmlBenchFunction(learner.name, task.id)
par.set = getParamSet(of)
res = of(sampleValue(par.set))
res
des = generateGridDesign(par.set, 100)
res = of(des)
des$y = as.numeric(res)
des$distance = purrr::map_dbl(attr(res, "extras"), "distances")
mdes = reshape2::melt(des, measure.vars = c("alpha", "lambda"))
library(ggplot2)
g = ggplot(des, aes(x = alpha, y = lambda, fill = distance))
g + geom_tile()

stopOmlTuneServer()



learner.name = "classif.svm"
task.id = 3

of = makeOmlBenchFunction(learner.name, task.id, include.extras = TRUE, api.chunksize = 200)
par.set = getParamSet(of)
set.seed(1)
x2 = generateRandomDesign(3, par.set)
dput(x2)
res = of(x2)