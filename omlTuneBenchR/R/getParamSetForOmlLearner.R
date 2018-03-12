#' @title Get ParamSet for Learner Name
#' @description Returns a ParamSet Object for a given Learner
#' 
#' @param learner.name [`character(1)`]
#'   The learner class (e.g. "classif.glmnet")
#'
#' @return [`ParamSet`]
getParamSetForOmlLearner = function(learner.name) {
  assertChoice(learner.name, names(omlTuneBenchR$parameter_ranges))  
  omlTuneBenchR$parameter_ranges[[learner.name]]
}
