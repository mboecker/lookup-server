#' @title Creates a function that will wrap the API
#' @description Wraps the API Call in a function that returns the performance of a defined learner and `task.id` for a given `x` using the OmlBench API.
#' @param learner.name (`character(1)`)
#'   Defines the learner.
#' @param task.id (`integer(1)`)
#'   Defines the task id the learner is optimized on.
#' @return `function`
#' @export

makeOmlBenchFunction = function(learner.name, task.id, api.chunksize = 20, include.extras = FALSE, objective = "accuracy") {
  assertString(learner.name)
  assertInt(task.id)
  assertSubset(objective, c("auc", "accuracy", "rmse"))

  par.set = getParamSetForOmlLearner(learner.name)
  
  makeSingleObjectiveFunction(
    name = paste0("Task_", task.id, "_Learner_", learner.name),
    fn = function(x) readApiResult(x, learner.name, task.id, include.extras, api.chunksize, objective),
    has.simple.signature = FALSE,
    vectorized = FALSE,
    par.set = par.set,
    noisy = FALSE,
    minimize = objective %in% c("rmse") #We get accuracy back right?
  )
}

readApiResult = function(x, learner.name, task.id, include.extras, api.chunksize, objective) {
  # x can be a list with each list item representing value(s) for each parameter
  # or a data.frame directly resulting from as.data.frame(x)
  if (is.list(x) && !is.data.frame(x)) {
    assertList(x, names = "named", types = c("numeric", "integer", "logical", "character"))
    x = as.data.frame(x)
  } else {
    assertDataFrame(x)
  }
  assertSetEqual(names(x), getParamIds(par.set, repeated = TRUE, with.nr=TRUE))

  # we split x into chunks smaller then 20 so that the api can handle it.
  x = split(x, ceiling(seq_len(nrow(x))/api.chunksize))
  # we will get a nested list, each list item are the result of one chunk
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
  res = unlist(chunked.res, recursive = FALSE, use.names = FALSE) # unlist, so we have a list with each item corresponding to one x value
  y = sapply(res, function(x) x[[objective]], simplify = TRUE) # y will be the eg. accuracy as a numeric vector
  # add extras as a non-nested list. each i-th item corresponds to the i-th entry in the y vecotr
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
