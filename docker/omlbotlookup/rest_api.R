source("data_access.R")

########################################################################################################################

#* @serializer unboxedJSON
#* @get /
rest_estimate_performance = function(res, req, task = NULL, algo = NULL, ...) {
  # Get request parameters as named list.
  parameters = list(...)
  task_id = task
  
  if(is.null(task_id) || !is_number(task_id)) {
    err_msg = "Please give the task argument as a number."
    return(json_error(err_msg))
  }
  
  if(is.null(algo)) {
    err_msg = "Please give the algo argument."
    return(json_error(err_msg))
  }
  
  # Find algorithm_name / algorithm_ids
  if(is_number(algo)) {
    algo_ids = algo
    algo_name = get_algo_name_for_algo_id(algo_ids)
  } else {
    algo_ids = get_algo_ids_for_algo_name(algo)
    algo_name = algo
  }
  
  if(length(algo_ids) == 0) {
    return(json_error("No such algorithm was found in the database."))
  }
  
  if(length(parameters) == 0) {
    return(json_error("No parameters given."))
  }
  
  # Check needed parameters
  parameter_status = is_parameter_list_ok(algo_name, parameters)
  if(!isTRUE(parameter_status)) {
    return(parameter_status)
  }
  
  # Lookup performance in database
  result = get_nearest_setup(algo_ids, algo_name, task_id, parameters)
  
  if(is.null(result)) {
    return(json_error("An error occured."))
  }
  
  if(!is.null(result$error)) {
    return(list(error = result$error))
  } else {
    performance = get_setup_data(task_id, result)
    performance = performance[[1]]
    return(append(result, performance))
  }
}

########################################################################################################################

# List all possible tasks.
#* @get /tasks
rest_tasks = function() {
  all_task_ids = get_possible_task_ids()
  return(list(possible_task_ids = all_task_ids))
}

########################################################################################################################

# List all possible parameters for given algorithm
#* @serializer unboxedJSON
#* @get /params
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

########################################################################################################################

# List all possible algorithm ids for the given task.
#* @serializer unboxedJSON
#* @get /algos
rest_algos <- function(task = NULL) {
  task_id = task
  
  if(is.null(task_id) || !is_number(task_id)) {
    error_msg = "Please supply the parameter 'task_id' for which you want the algorithm list as a number."
    return(json_error(error_msg))
  }
  
  possible_algos = get_algos_for_task(task_id)
  
  return(list(possible_algo_names = names(possible_algos), possible_algo_ids = numeric(0)))
}

########################################################################################################################
