library(RMySQL)
library(checkmate)
library(ParamHelpers)

mysql_username = "root"
mysql_password = ""
mysql_dbname = "openml"
mysql_host = "127.0.0.1"

con <- dbConnect(MySQL(), user = mysql_username, password = mysql_password, dbname = mysql_dbname, host = mysql_host)

# This is set to limit the queries to our bot, uploader id 2702.
uploader = 2702

# See /docker/preparation/prepare_parameter_ranges.R for instructions.
# This file contains parameter range data obtained from the omlbot-sourcecode.
parameter_ranges = readRDS("parameter_ranges.Rds")

# This file can generate the rather complex euclidean-sorting query used for nearest neighbor calculation.
source("sql_generator.R")

# This runs MySQL-Escape-String on the given named list.
# This secures the API for MySQL-Injection-Attacks.
escapeParameterList = function(con, parameters) {
  unescaped_names = as.character(names(parameters))
  escaped_names = dbEscapeStrings(con, unescaped_names)
  unescaped_values = as.character(unlist(unname(parameters)))
  escaped_values = dbEscapeStrings(con, unescaped_values)
  return(setNames(as.list(escaped_values), escaped_names))
}

# This is the most interesting function in here.
# Actual lookup happens here.
# Returns a named list with either $error set, or the results of the lookup ($performance, ...)
predict_point = function(impl_id, task_id, parameters) {
  return_value = list()
  
  # The following commands secure the API for MySQL-Injection-Attacks.
  if(!testInt(impl_id)) {
    return_value$error = "Please give implementation_id as a number.";
    return(return_value)
  }
  if(!testInt(task_id)) {
    return_value$error = "Please give task_id as a number.";
    return(return_value)
  }
  parameters = escapeParameterList(con, parameters)
  
  # Load parameter names for this algorithm
  sql.exp = paste0("SELECT id, name FROM input WHERE implementation_id = ", impl_id)
  query_results = dbGetQuery(con, sql.exp)
  
  if(dim(query_results)[1] == 0) {
    return_value$error = "The algorithm you gave by implementation_id does not exist in this database."
    return(return_value)
  }
  
  # This contains the names for the parameters required by the chosen algorithm.
  parameter_names = query_results$name
  
  # This contains the IDs for the parameters.
  parameter_ids = query_results$id
  
  # This is the amount of parameters supplied.
  n_parameters = length(parameters)
  
  # This will contain the input_ids for the supplied parameters in correct order.
  parameter_ids_sorted = rep(0, n_parameters)
  
  # match function parameters onto input.name
  for (i in 1:n_parameters) {
    idx = which(parameter_names == names(parameters[i]))

    if(length(idx) == 0) {
      return_value$error = paste0("This supplied parameter is not applicable: ", names(parameters)[i])
      return(return_value)
    }
    else {
      parameter_ids_sorted[i] = parameter_ids[idx]
    }
  }
  
  # First, look in run for the task_id
  sql.exp = paste0("SELECT * FROM run WHERE uploader = ", uploader, " AND task_id = ", task_id);
  run_data = dbGetQuery(con, sql.exp)
  
  if(dim(run_data)[1] == 0) {
    return_value$error = "The task you requested has not yet been evaluated by the specified uploader."
    return(return_value)
  }
  
  # then, look in input_setting for the input_ids (for the names of parameters) and data on closest point.
  # (This can be loaded into memory)
  sql.exp = generate_query(task_id, parameter_ids_sorted, simplify2array(parameters))
  setup_data = dbGetQuery(con, sql.exp)
  
  if(dim(setup_data)[1] == 0) {
    return_value$error = "No suitable points found in the database."
    return(return_value)
  }
  
  # For now, use the nearest point.
  # TODO: add interpolation if two points are on opposite sides.
  first_distance = setup_data$sum_distance[1]
  setup_id = setup_data$setup[1]
  
  # Request actual point data on the chosen nearest point
  sql.exp = paste0("SELECT i.name, s.value FROM input_setting AS s JOIN input AS i WHERE s.input_id = i.id and s.setup = ", setup_id);
  nearest_point_data_raw = dbGetQuery(con, sql.exp)
  
  # Convert to named list
  nearest_point_data = as.list(nearest_point_data_raw$value)
  names(nearest_point_data) = nearest_point_data_raw$name
  
  # Now, we request performance data on the nearest point given by the database.
  # TODO: find out if function_id 4 is correct.
  sql.exp = paste0("SELECT AVG(value) FROM evaluation WHERE source IN (SELECT rid FROM run WHERE task_id = ", task_id, " AND setup = ", setup_id, ") AND function_id = 4");
  performance_data = dbGetQuery(con, sql.exp)
  
  # Save information in the return_value.
  return_value$performance = as.numeric(performance_data)
  return_value$nearest_setup = setup_id
  return_value$nearest_setup_distance = first_distance
  return_value$nearest_setup_real_values = nearest_point_data
  return_value$impl_id_used = impl_id
  
  return(return_value)
}

json_error <- function(err_msg, more=list()) {
  append(list(error_message = err_msg), more)
}

#* @serializer unboxedJSON
#* @get /
lookup <- function(...) {
  
  # Get request parameters as named list.
  ls = as.list(match.call())
  
  # Remove first three entries (because they're not useful).
  ls[0:3] = NULL

  # This will contain some kind of "warnings" for the api.
  notices = list()

  # Check, if algorithm is given.
  if(!("algo" %in% names(ls))) {
    error_msg = "Please give the machine learning algorithm you want to use as a parameter (algo=x)."
    return(json_error(error_msg, more=list(missing_args = "algo")))
  }
  
  impl_id = ls[["algo"]]
  ls[["algo"]] = NULL

  # If the algo argument is not numeric, it is treated as an algorithm name instead.
  # We then look up the database for the correct algo_ids.
  if(!testInt(as.numeric(impl_id))) {
    algo_name = dbEscapeStrings(con, as.character(impl_id))
    sql.exp = paste0("SELECT id FROM implementation WHERE name = '", algo_name, "'")
    result = dbGetQuery(con, sql.exp)
    
    if(dim(result)[1] == 0) {
      error_msg = "There is no algorithm in the database with this name."
      return(json_error(error_msg))
    }
    
    impl_id = as.numeric(c(simplify2array(result)))
  } else {
    impl_id = as.numeric(impl_id)
  }
  
  # Check, if task is given.
  if(!("task" %in% names(ls))) {
    error_msg = "Please give the machine learning task you want to use as a parameter (task=x)."
    return(json_error(error_msg, more=list(missing_args = "task")))
  }
  
  task_id = as.numeric(ls[["task"]])
  ls[["task"]] = NULL
  
  # Check, if task_id is correctly formed.
  if(!testInt(task_id)) {
    error_msg = "Please give the machine learning task you want to use in numeric form (task_id)."
    return(json_error(error_msg, more=list(malformed_args = "task")))
  }
  
  if(length(ls) == 0) {
    error_msg = "Please supply the parameters you want to set for the algorithm."
    return(json_error(error_msg))
  }

  result = lapply(impl_id, function(algo_id) {
    predict_point(algo_id, task_id, ls)
  })
  
  result = result[unlist(lapply(result, function(r) !is.null(r$nearest_setup_distance)))]
  
  if(length(result) == 0) {
    error_msg = "No fitting points were found in the database."
    return(json_error(error_msg))
  }
  
  best = which.min(unlist(lapply(result, function(r) r$nearest_setup_distance)))
  result = result[[best]]
  
  if(is.null(result$error)) {
    response = list(performance = result$performance,
                  distance = result$nearest_setup_distance,
                  nearest_setup = list(id = result$nearest_setup,
                                       impl_id = result$impl_id_used,
                                       values = result$nearest_setup_real_values))
  } else {
    response = list(error = result$error)
  }

  if(length(notices) > 0) {
    response = append(response, list(notices = notices))
  }
  
  return(response)
}

# List all possible tasks.
#* @get /tasks
tasks <- function() {
  sql.exp = "SELECT DISTINCT task_id FROM run"
  return(list(possible_task_ids = simplify2array(dbGetQuery(con, sql.exp))))
}

# List all possible algorithm ids for the given task.
#* @serializer unboxedJSON
#* @get /algos
algos <- function(task = "") {
  return_value = list()
  
  # The following commands secure the API for MySQL-Injection-Attacks.
  task_id = as.numeric(task)
  if(!testInt(task_id)) {
    return_value$error = "Please give the argument task as a number.";
    return(return_value)
  }
  
  # This requests every run setup with the given task.
  setup_ids = paste0("SELECT DISTINCT setup FROM run WHERE task_id = ", task_id)
  
  # This requests the input_ids on every of these setups.
  input_ids = paste0("SELECT DISTINCT input_id FROM input_setting WHERE setup IN (", setup_ids, ")")
  
  # This requests the implementation_id to every of these input_ids.
  sql.exp = paste0("SELECT DISTINCT implementation_id, implementation.fullName FROM input INNER JOIN implementation ON implementation.id = input.implementation_id AND input.id IN (", input_ids, ")")
  
  result = dbGetQuery(con, sql.exp)
  
  # This are the algorithm ids.
  impl_ids = result$implementation_id
  
  # For convenience, we also list the algorithms name.
  impl_names = as.list(result$fullName)
  names(impl_names) = result$implementation_id
  
  return(list(possible_algo_ids = impl_ids, algorithm_names = impl_names))
}

# List all possible parameters for given algorithm
#* @serializer unboxedJSON
#* @get /parameters
parameters <- function(algo = "") {
  return_value = list()
  
  impl_id = algo
  
  # The following commands secure the API for MySQL-Injection-Attacks.
  if(!testInt(as.numeric(impl_id))) {
    impl_id = dbEscapeStrings(con, impl_id)
    algo_name = impl_id
    impl_id = NULL
  } else {
    # Request algo name from database
    sql.exp = paste0("SELECT name FROM implementation WHERE id = '", impl_id, "'")
    result = dbGetQuery(con, sql.exp)
    algo_name = result$name
    
    if (dim(result)[1] == 0) {
      return_value$error = "No algorithm with that ID found in the database.";
      return(return_value)
    }
  }
  
  # Algorithm names in the database have a leading "mlr." in front of their name.
  # We delete this.
  if (substring(algo_name, 1, 4) == "mlr.") {
    algo_name = substring(algo_name, 5)
  }
  
  # Extract parameter ranges from database.
  if (is.null(parameter_ranges[[algo_name]])) {
    return_value$notice = "This algorithm was not found in the parameter_ranges file, which is extracted from the omlbot source. Parameters were reconstructed from the OpenML database."
    
    if(is.null(impl_id)) {
      return_value$error = "When using the algorithm name instead of the algorithm id, parameter range reconstruction is (currently) not possible."
      return(return_value)
    }
    
    # Prepare SQL statement
    sql.exp = paste0("SELECT i.name, MIN(s.value) AS min, MAX(s.value) AS max FROM input AS i JOIN input_setting AS s WHERE s.input_id = i.id AND i.implementation_id = ", impl_id, " GROUP BY i.name");
    result = dbGetQuery(con, sql.exp)
    
    if(dim(result)[1] == 0) {
      return_value$error = "No parameter data was found in the database for this algorithm."
      return(return_value)
    }
    
    # Prepare ranges-list and apply names
    ranges = as.list(result$min)
    names(ranges) = result$name
    
    mins = result["min"]
    maxs = result["max"]
    
    # Fill with min-max-data
    for(i in 1:length(ranges)) {
      ranges[[i]] = list(lower = mins[i,], upper = maxs[i,])
    }
    
    return_value$parameter_ranges = ranges
  } else {
    # Load parameter data from pre-saved file "parameter_ranges".
    # See call to readRDS() on top of this file.
    params = parameter_ranges[[algo_name]]
    
    return_value$parameter_ranges = params$pars
  }
  
  return(return_value)
}
