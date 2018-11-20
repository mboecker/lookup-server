#' @title Get ParamSet for Learner Name
#' @description Returns a ParamSet Object for a given Learner
#' 
#' @param learner.name (`character(1)`)
#'   The learner class (e.g. "classif.glmnet")
#'
#' @return [`ParamSet`]
getParamSetForOmlLearner = function(learner.name) {
  assertChoice(learner.name, names(parameter_ranges))  
  par.set = parameter_ranges[[learner.name]]
  par.set$pars = lapply(par.set$pars, function(x) {
      x$trafo = x$trafo.inverse = NULL
      return(x)
    }
  )
  return(par.set)
}
