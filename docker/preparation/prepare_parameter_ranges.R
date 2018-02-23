library("mlr")
library("ranger")
library("kknn")
library("e1071")
library("xgboost")

# This function is taken from https://github.com/ja-thomas/OMLbots/blob/master/R/botMakeLrnPsSets.R
# It is licensed under GNU GPL v2.
makeLrnPsSets = function(learner, param.set, lrn.ps.sets = NULL, 
                         id = paste0(learner$id, ".set"), overwrite = FALSE) {
  
  par.match = names(param.set$pars) %in% names(learner$par.set$pars)
  if(all(par.match)){
    ls = list(learner = learner, param.set = param.set)
  } else {
    stop(paste("The following parameters in param.set are not included in learner:", 
               paste(names(param.set$pars[par.match == FALSE]), collapse = ", ")))
  }
  
  if(is.null(lrn.ps.sets)){
    lrn.ps.sets = list()
    lrn.ps.sets[[id]] = ls
    attr(lrn.ps.sets, "class") = "LrnPsSet"
  } else {
    if(id %in% names(lrn.ps.sets) & overwrite == FALSE){
      stop("tune.pair already contains id: \"", id, "\". Please specify a new id or set overwrite = TRUE.")
    } else {
      lrn.ps.sets[[id]] = ls
    }
  }
  
  return(lrn.ps.sets)
}

# This function is taken from https://github.com/ja-thomas/OMLbots/blob/master/R/botSetLearnerParamPairs.R#L6
# It is licensed under GNU GPL v2.
getSimpleLearners = function(){
  # Simple learner param set
  simple.lrn.par.set = makeLrnPsSets(learner = makeLearner("classif.glmnet", predict.type = "prob"),
                                     param.set = makeParamSet(
                                       makeNumericParam("alpha", lower = 0, upper = 1, default = 1),
                                       makeNumericVectorParam("lambda", len = 1L, lower = -10, upper = 10, default = 0 ,trafo = function(x) 2^x)))
  
  simple.lrn.par.set = makeLrnPsSets(learner = makeLearner("classif.rpart", predict.type = "prob"), 
                                     param.set = makeParamSet(
                                       makeNumericParam("cp", lower = 0, upper = 1, default = 0.01),
                                       makeIntegerParam("maxdepth", lower = 1, upper = 30, default = 30),
                                       makeIntegerParam("minbucket", lower = 1, upper = 60, default = 1),
                                       makeIntegerParam("minsplit", lower = 1, upper = 60, default = 20)), 
                                     lrn.ps.sets = simple.lrn.par.set)
  
  return(simple.lrn.par.set)
}

# This function is taken from https://github.com/ja-thomas/OMLbots/blob/master/R/botSetLearnerParamPairs.R#L29
# It is licensed under GNU GPL v2.
getMultipleLearners = function(){
  simple.lrn.par.set = getSimpleLearners()
  
  # increase to a general param set
  lrn.par.set = makeLrnPsSets(learner = makeLearner("classif.kknn", predict.type = "prob"), 
                              param.set = makeParamSet(
                                makeIntegerParam("k", lower = 1, upper = 30)),
                              lrn.ps.sets = simple.lrn.par.set)
  
  lrn.par.set = makeLrnPsSets(
    learner = makeLearner("classif.svm", predict.type = "prob"), 
    param.set = makeParamSet(
      makeDiscreteParam("kernel", values = c("linear", "polynomial", "radial")),
      makeNumericParam("cost", lower = -10, upper = 10, trafo = function(x) 2^x),
      makeNumericParam("gamma", lower = -10, upper = 10, trafo = function(x) 2^x, requires = quote(kernel == "radial")),
      makeIntegerParam("degree", lower = 2, upper = 5, requires = quote(kernel == "polynomial"))),
    lrn.ps.sets = lrn.par.set)
  
  lrn.par.set = makeLrnPsSets(
    learner = makeLearner("classif.ranger", predict.type = "prob"), 
    param.set = makeParamSet(
      makeIntegerParam("num.trees", lower = 1, upper = 2000),
      makeLogicalParam("replace"),
      makeNumericParam("sample.fraction", lower = 0.1, upper = 1),
      makeNumericParam("mtry", lower = 0, upper = 1),
      makeLogicalParam(id = "respect.unordered.factors"),
      makeNumericParam("min.node.size", lower = 0, upper = 1)),
    lrn.ps.sets = lrn.par.set)
  
  lrn.par.set = makeLrnPsSets(
    learner = makeLearner("classif.xgboost", predict.type = "prob"), 
      param.set = makeParamSet(
        makeIntegerParam("nrounds", lower = 1, upper = 5000), 
        makeNumericParam("eta", lower = -10, upper = 0, trafo = function(x) 2^x),
        makeNumericParam("subsample",lower = 0.1, upper = 1),
        makeDiscreteParam("booster", values = c("gbtree", "gblinear")),
        makeIntegerParam("max_depth", lower = 1, upper = 15, requires = quote(booster == "gbtree")),
        makeNumericParam("min_child_weight", lower = 0, upper = 7, requires = quote(booster == "gbtree"), trafo = function(x) 2^x),
        makeNumericParam("colsample_bytree", lower = 0, upper = 1, requires = quote(booster == "gbtree")),
        makeNumericParam("colsample_bylevel", lower = 0, upper = 1, requires = quote(booster == "gbtree")),
        makeNumericParam("lambda", lower = -10, upper = 10, trafo = function(x) 2^x),
        makeNumericParam("alpha", lower = -10, upper = 10, trafo = function(x) 2^x)),
      lrn.ps.sets = lrn.par.set)
  
  return(lrn.par.set)
}

# This function generates a named list with an entry for every known algorithm.
# For every algorithm it has upper and lower bounds on each parameter.
parameters = function() {
  raw_data = getMultipleLearners()
  
  params_per_algo = list()
  
  for (y in raw_data) {
    named_outer_list = list()
    param_requirements = list()
    
    for (x in y$param.set$pars) {
      new_list = list(list(lower = x$lower, upper = x$upper))
      names(new_list) = x$id 
      param_requirements = append(param_requirements, new_list)
    }
    
    named_outer_list = list(param_requirements)
    names(named_outer_list) = y$learner$id
    
    params_per_algo = append(params_per_algo, named_outer_list)
  }
  
  return(params_per_algo)
}

parameter_ranges = parameters()

saveRDS(parameter_ranges, file = "../omlbotlookup/parameter_ranges.Rds")
