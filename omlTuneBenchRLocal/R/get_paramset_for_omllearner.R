#' @title Get ParamSet for learner_id
#' @description Returns a ParamSet Object for a given Learner
#' 
#' @param learner_id (`character(1)`)
#'   The learner class (e.g. "classif.glmnet")
#'
#' @return [`ParamSet`]
get_paramset_for_omllearner = function(learner_id) {
  assertChoice(learner_id, names(parameter_ranges))  
  par.set = parameter_ranges[[learner_id]]
  par.set$pars = lapply(par.set$pars, function(x) {
      x$trafo = x$trafo.inverse = NULL
      return(x)
    }
  )
  return(par.set)
}
