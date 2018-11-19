#' @title Creates a function that will wrap the API
#' @description Wraps the API Call in a function that returns the performance of a defined learner and `task_id` for a given `x` using the OmlBench API.
#' @param learner_id (`character(1)`)
#'   Defines the learner. (e.g. `"classif.rpart"`)
#' @param task_id (`integer(1)`)
#'   Defines the task_id the learner is optimized on.
#' @param api.chunksize (`numeric(1)`)
#'   If too many points are requested with one function call this can help to split the request into smaller chunks.
#' @param include.extras (`logical(1)`)
#'   Should the extras be attached as an attribute?
#' @param objective (`character(1)`)
#'   Which value should be optimized? Possible choices are \dQuote{auc}, \dQuote{accuracy} (default) and \dQuote{rmse}.
#' @return `function`
#' @export

makeOmlBenchFunction = function(learner_id, task_id, include.extras = FALSE, objective = "accuracy") {
  assertString(learner_id)
  assertInt(task_id)
  assertSubset(objective, c("auc", "accuracy", "rmse"))

  par.set = getParamSetForOmlLearner(learner_id)
  
  makeSingleObjectiveFunction(
    name = paste0("Task_", task_id, "_Learner_", learner_id),
    fn = function(x) findNearestNeighbor(x, learner_id, task_id, include.extras, objective, par.set),
    has.simple.signature = FALSE,
    vectorized = FALSE,
    par.set = par.set,
    noisy = FALSE,
    minimize = objective %in% c("rmse") #We get accuracy back right?
  )
}

findNearestNeighbor = function(x, learner_id, task_id, include.extras, objective, par.set) {
 
  if (include.extras) {
    extras = lapply(res, function(x) {
      x[[objective]] = NULL
      setNames(x, paste0(".lookup.", names(x)))
    })
    if (length(y) == 1) extras = extras[[1]]
    attr(y, "extras") = extras
  }
  
  return(y)
}
