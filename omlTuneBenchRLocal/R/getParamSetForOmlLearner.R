#' @title Get ParamSet for learner_id
#' @description Returns a ParamSet Object for a given Learner
#' 
#' @param learner_id (`character(1)`)
#'   The learner class (e.g. "classif.glmnet")
#'
#' @return [`ParamSet`]
getParamSetForOmlLearner = function(learner_id) {
  assertChoice(learner_id, names(omlTuneBenchR$parameter_ranges))  
  par.set = omlTuneBenchR$parameter_ranges[[learner_id]]
  par.set$pars = lapply(par.set$pars, function(x) {
      x$trafo = x$trafo.inverse = NULL
      return(x)
    }
  )
  return(par.set)
}
