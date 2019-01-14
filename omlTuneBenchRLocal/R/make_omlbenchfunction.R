#' @title Creates a function that will wrap the API
#' @description Wraps the API Call in a function that returns the performance of a defined learner and `task_id` for a given `x` using the OmlBench API.
#' @param learner_id (`character(1)`)
#'   Defines the learner. (e.g. `"classif.rpart"`)
#' @param task_id (`integer(1)`)
#'   Defines the task_id the learner is optimized on.
#' @param include.extras (`logical(1)`)
#'   Should the extras be attached as an attribute?
#' @param objective (`character(1)`)
#'   Which value should be optimized? Possible choices are \dQuote{auc}, \dQuote{accuracy} (default) and \dQuote{rmse}.
#' @return `function`
#' @export

make_omlbenchfunction = function(learner_id, task_id, include.extras = FALSE, objective = "accuracy") {
  assertString(learner_id)
  assertInt(task_id)
  assertSubset(objective, c("auc", "accuracy", "rmse"))

  par.set = get_paramset_for_omllearner(learner_id)
  
  fun = makeSingleObjectiveFunction(
    name = paste0("Task_", task_id, "_Learner_", learner_id),
    fn = function(x) objective_wrapper(x, learner_id, task_id, include.extras, objective, par.set),
    has.simple.signature = FALSE,
    vectorized = FALSE,
    par.set = par.set,
    noisy = FALSE,
    minimize = objective %in% c("rmse") #We get accuracy back right?
  )
  class(fun) = c("omlbenchfunction", class(fun))
  return(fun)
}

objective_wrapper = function(x, learner_id, task_id, include.extras, objective, par.set) {

  x = as.data.table(x)

  x = type_fix(x, par.set)

  res = get_nearest_setup(learner_id, task_id, x)
  y = res[[objective]]

  if (include.extras) {
    extras = res[, {
      tmp = as.list(.SD)
      setattr(tmp, ".data.table.locked", NULL)
      tmp[[objective]] = NULL
      names(tmp) = paste0(".lookup.", names(tmp))
      list(extras = list(tmp))
    }, by = seq_len(nrow(res))]
    extras = extras$extras
    if (length(y) == 1) extras = extras[[1]]
    attr(y, "extras") = extras
  }
  
  return(y)
}
