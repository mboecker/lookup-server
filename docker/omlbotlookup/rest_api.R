# Include data access functions
source("data_access.R")

#' List all possible algorithm ids for the given task.
#' @serializer unboxedJSON
#' @get /algos
rest_algos <- function() {
  get_algos()
}

#' Return the performance of the closest points
#' @serializer unboxedJSON
#' @param task the task id
#' @param algo the algorithm name (e.g. classif.knn) (without leading mlr. as in the DB)
#' @param parameters named list of parameter settings. Will be converted to a data.frame. Each row represents one parameter setting.
#' @get /
#' @post /
rest_estimate_performance = function(task = NULL, algo = NULL, parameters = NULL) {
  task = as.numeric(task)
  
  if(is.null(parameters)) {
    return(json_error("Please supply 'parameters'."))
  }
  
  parameters = tryCatch(jsonlite::fromJSON(parameters), error = function(e) e)
  if (inherits(parameters, c("try-error", "error"))) {
    return(json_error(sprintf("Error in converting parameters from JSON: %s", as.character(parameters))))
  } else if (!isTRUE({err_msg = checkList(parameters, names = "named")})) {
    return(json_error(sprintf("parameters = %s: %s",parameters, err_msg)))
  }
  
  parameters = lapply(parameters, function(x) if (is.character(x)) type.convert(x) else x)
  parameters = as.data.table(parameters)
  
  if (!isTRUE({err_msg = checkInt(task)})) {
    return(json_error(sprintf("task = %s: %s",task, err_msg)))
  }
  
  if (!isTRUE({err_msg = checkString(algo)})) {
    return(json_error(sprintf("algo = %s: %s", algo, err_msg)))
  }
  
  if(length(algo) == 0) {
    return(json_error("No algo given."))
  }
  
  # Check needed parameters
  if (ncol(parameters) == 1) { #FIXME: Workaround for PH bug!
    parameter_list = lapply(parameters[[1]], function(x) setNames(list(x), names(parameters)))
  } else {
    parameter_list = dfRowsToList(
      as.data.frame(parameters[, getParamIds(parameter_ranges[[algo]]), with = FALSE]), 
      parameter_ranges[[algo]],
      ints.as.num = TRUE)  
  }
  parameter_status = sapply(parameter_list, function(x) is_parameter_list_ok(algo, x))
  parameter_status_ok = sapply(parameter_status, isTRUE)
  if (!all(parameter_status_ok)) {
    error_messages = paste0("#", which(!parameter_status_ok), ": ", parameter_status[!parameter_status_ok], collapse = ", ")
    return(json_error(paste0("Errors for parameter values: ", error_messages)))
  }
  
  # Lookup performance in database
  result = get_nearest_setup(algo, task, parameters)
  
  if(is.null(result)) {
    return(json_error("An error occured."))
  }
  
  if(!is.null(result$error)) {
    return(json_error(paste(result$error, collapse = ", ")))
  } else {
    return(result)
  }
}

# List all possible parameters for given algorithm
#' @serializer unboxedJSON
#' @get /params
rest_params = function(algo = NULL) {
  if(is.null(algo)) {
    error_msg = "Please supply the parameter 'algo' for which you want the parameter list."
    return(json_error(error_msg))
  }
  
  if(is_number(algo)) {
    algo_name = get_algo_name_for_algo_id(algo)
    
    if(length(algo_name) == 0) {
      error_msg = names(last_warning)[1]
      return(json_error(error_msg))
    }
  } else {
    algo_name = algo
  }
  
  params = get_params_for_algo(algo_name)
  
  if(length(params) == 0) {
    error_msg = paste0("No parameter data found for algorithm '", algo_name, "'.")
    return(json_error(error_msg))
  }
  
  return(list(params = params))
}

# List all possible tasks.
#' @get /tasks
rest_tasks = function() {
  all_task_ids = get_possible_task_ids()
  return(list(possible_task_ids = all_task_ids))
}

# List all possible performance values for a given task + algo combination.
#' @get /ally
rest_all_performances = function(task = NULL, algo = NULL) {
  if(is.null(task)) {
    error_msg = "Please supply the parameter 'task' for which you want the performances"
    return(json_error(error_msg))
  }
  
  if(is.null(algo)) {
    error_msg = "Please supply the parameter 'algo' for which you want the performances"
    return(json_error(error_msg))
  }
  
  all_y = get_all_y(task, algo)
  return(all_y)
}
