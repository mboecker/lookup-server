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
    # we split x into chunks smaller then 1000 so that the api can handle it.
    x = as.data.frame(x)
    x = split(x, ceiling(seq_len(nrow(x))/200))
    chunked.res = lapply(x, function(xs) {
      query = list(task = task.id, algo = learner.name, parameters = jsonlite::toJSON(as.list(xs)))
      httr.res = httr::POST(omlTuneBenchR$connection, query = query, httr::accept_json())
      res = httr::content(httr.res)
      if (!is.null(res$error)) {
        stop(res$error)
      } else {
        return(res)
      }
    })
    res = unlist(chunked.res, recursive = FALSE)
    y = sapply(res, function(x) x$performance, simplify = TRUE)
    attr(y, "extras") = lapply(res, function(x) x[setdiff(names(x), "performance")])
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
