# Include data access functions
source("data_access.R")

#' List all possible algorithm ids for the given task.
#' @serializer unboxedJSON
#' @get /algos
rest_algos <- function() {
  list(possible_algo_ids = get_algos())
}

#' Return the performance of the closest points
#' @serializer unboxedJSON
#' @param task [numeric(1)] the task id
#' @param algo [character(1)] the algorithm name (e.g. classif.knn) (without leading mlr. as in the DB)
#' @param parameters [list] named list of untransformed parameter settings. 
#' Each list item contains the vector of settings for one parameter. All vectors have to be of the same length. Will be converted to a data.frame. Each row represents one parameter setting.
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

  par_set = parameter_ranges[[algo]]
  parameters = type_save_convert(parameters, par_set)
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
  parameter_list = .mapply(list, parameters, list())
  parameter_status = sapply(parameter_list, function(x) is_parameter_list_ok(algo, x))
  parameter_status_ok = sapply(parameter_status, isTRUE)
  if (!all(parameter_status_ok)) {
    error_messages = paste0("#", which(!parameter_status_ok), ": ", parameter_status[!parameter_status_ok], collapse = ", ")
    return(json_error(paste0("Errors for parameter values: ", error_messages)))
  }
  
  # Lookup performance in database
  result = tryCatch(get_nearest_setup(algo, task, parameters), error = function(e) e)
  if (inherits(result, c("try-error", "error"))) {
    return(json_error(sprintf("Error in getting nearest setup: %s", as.character(result))))
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
#' @param restrict [logical(1)] Restrict output to tasks in paper
rest_tasks = function(restrict = FALSE) {
  all_task_ids = get_possible_task_ids()
  if(isTRUE(restrict) || restrict == "TRUE" || restrict == 1) {
    task_ids_paper = task_ids_paper()
    all_task_ids = intersect(all_task_ids, task_ids_paper)
    if (any(!task_ids_paper %in% all_task_ids)) {
      return(json_error("Some tasks that are requested are not in the Database."))
    }
  }
  return(list(possible_task_ids = all_task_ids))
}

# List all possible performance values for a given task + algo combination.
#' @serializer contentType list(type="application/octet-stream")
#' @get /rds
rest_rds = function(task = NULL, algo = NULL) {
  if(is.null(task)) {
    error_msg = "Please supply the parameter 'task' for which you want the performances"
    return(json_error(error_msg))
  }
  
  if(is.null(algo)) {
    error_msg = "Please supply the parameter 'algo' for which you want the performances"
    return(json_error(error_msg))
  }
  complete_table = get_table(algo, task)
  setDF(complete_table)
  tfile = tempfile()
  saveRDS(complete_table, file = tfile)
  readBin(tfile, "raw", n=file.info(tfile)$size)
}

# List all possible performance values for a given task + algo combination.
#' @serializer contentType list(type="application/octet-stream")
#' @get /csv
rest_csv = function(task = NULL, algo = NULL) {
  if(is.null(task)) {
    error_msg = "Please supply the parameter 'task' for which you want the performances"
    return(json_error(error_msg))
  }
  
  if(is.null(algo)) {
    error_msg = "Please supply the parameter 'algo' for which you want the performances"
    return(json_error(error_msg))
  }
  
  complete_table = get_table(algo, task)
  tfile = tempfile()
  write.csv(complete_table, file = tfile)
  readBin(tfile, "raw", n=file.info(tfile)$size)
}

#' List an overview of the data in the database.
#' @get /overview
rest_overview = function() {
  get_overview_table()
}
