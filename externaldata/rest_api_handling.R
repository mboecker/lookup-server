library(RMySQL)

mysql_username = "root"
mysql_password = ""
mysql_dbname = "openml"
mysql_host = "127.0.0.1"

con <- dbConnect(MySQL(), user = mysql_username, password = mysql_password, dbname = mysql_dbname, host = mysql_host)

source("/mysqldata/sql_generator.R")

predict_point = function(impl_id = 6767, task_id = 3896, parameters = list(alpha = 5, eta = 3)) {
  # Load parameter names for this algorithm
  sql.exp = paste0("SELECT id, name FROM input WHERE implementation_id = ", impl_id)
  query_results = dbGetQuery(con, sql.exp)
  
  if(dim(query_results)[1] == 0) {
    stop("The algorithm you gave by implementation_id does not exist in this database.")
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
      stop("This supplied parameter is not usable: ", names(parameters)[i])
    }
    else {
      parameter_ids_sorted[i] = parameter_ids[idx]
    }
  }
  
  # First, look in run for the task_id
  sql.exp = paste0("SELECT * FROM run WHERE uploader = ", uploader, " AND task_id = ", task_id);
  run_data = dbGetQuery(con, sql.exp)
  
  if(dim(run_data)[1] == 0) {
    stop("The task you requested has not yet been evaluated by the specified uploader.")
  }
  
  # then, look in input_setting for the input_ids (for the names of parameters) and data on closest point.
  # (This can be loaded into memory)
  sql.exp = generate_query(task_id, parameter_ids_sorted, simplify2array(parameters))
  setup_data = dbGetQuery(con, sql.exp)
  
  if(dim(setup_data)[1] == 0) {
    stop("No suitable points found in the database.")
  }
  
  # For now, use the nearest point.
  # TODO: add interpolation if two points are on opposite sides.
  setup_id = setup_data$setup[1]
  
  # Now, we request performance data on the nearest point given by the database.
  # TODO: find out if function_id 4 is correct.
  sql.exp = paste0("SELECT AVG(value) FROM evaluation WHERE source = (SELECT rid FROM run WHERE task_id = ", task_id, " AND setup = ", setup_id, ") AND function_id = 4");
  performance_data = dbGetQuery(con, sql.exp)
  
  return(as.numeric(performance_data))
}

json_error <- function(err_msg, more=list()) {
	append(list(error_message = err_msg), more)
}

#* @get /
lookup <- function(...) {
	ls <- as.list(match.call())
	ls[0:3] <- NULL

	notices = list()

	if(!("alg" %in% names(ls))) {
		error_msg = "Please give the machine learning algorithm you want to use as a parameter (alg=x)."
		return(json_error(error_msg, more=list(missing_args = "alg")))
	}

	algorithm = ls[["alg"]]

	expected_parameters = list("threshold", "k")

	missing_parameters = expected_parameters
	missing_parameters[expected_parameters %in% names(ls)] = NULL

	if(length(missing_parameters) > 0) {
		error_msg = paste0("Please supply adequat parameters for this machine learning algorithm. You are missing: ", paste0(missing_parameters, collapse=", "))
		return(json_error(error_msg, more=list(missing_parameters = simplify2array(missing_parameters))))
	}

	over_parameters = ls
	over_parameters["alg"] = NULL
	over_parameters[names(over_parameters) %in% expected_parameters] = NULL

	if(length(over_parameters) > 0) {
		error_msg = paste0("You supplied too many parameters for this machine learning algorithm: ", paste0(names(over_parameters), collapse=", "))
		notices = append(notices, error_msg)
	}

	response = list(performance = 0.0)

	if(length(notices) > 0) {
		response = append(response, list(notices = notices))
	}

	return(response)
}
