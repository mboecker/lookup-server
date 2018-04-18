#' @title Creates a function that will wrap the API
#' @description Wraps the API Call in a function that returns the performance of a defined learner and `task.id` for a given `x` using the OmlBench API.
#' @param learner.name (`character(1)`)
#'   Defines the learner.
#' @param task.id (`integer(1)`)
#'   Defines the task id the learner is optimized on.
#' @return `function`
#' @export

makeOmlBenchFunction = function(learner.name, task.id) {
  assertString(learner.name)
  assertInt(task.id)
  
  obj.fun = function(x) {
    query = list(task = task.id, algo = learner.name)
    query = c(query, as.list(x))
    httr.res = httr::GET(omlTuneBenchR$connection, query = query, httr::accept_json())
    res = httr::content(httr.res)
    if (!is.null(res$error)) {
      stop(res$error)
    }
    y = res$performance
    attr(y, "extras") = res[setdiff(names(res), "performance")]
    return(y)
  }
  
  par.set = getParamSetForOmlLearner(learner.name)
  
  makeSingleObjectiveFunction(
    name = paste0("Task_", task.id, "_Learner_", learner.name),
    fn = obj.fun,
    has.simple.signature = FALSE,
    vectorized = FALSE,
    par.set = par.set,
    noisy = FALSE,
    minimize = FALSE #We get accuracy back right?
  )
}
