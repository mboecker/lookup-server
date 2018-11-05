library("data.table")
library("RMySQL")
library("FNN")
library("memoise")
library("httr")
library("ParamHelpers")

source("paramToJSONList.R")
source("helper.R")

# Declare database credentials
mysql_username = "root"
mysql_password = ""
mysql_dbname = "openml"
mysql_host = "127.0.0.1"

# Delete the cache after 120 seconds
cache.timeout = 120

# Open database connection
con <- dbConnect(MySQL(), user = mysql_username, password = mysql_password, dbname = mysql_dbname, host = mysql_host)


# See /docker/preparation/prepare_parameter_ranges.R for instructions.
# This file contains parameter range data obtained from the omlbot-sourcecode.
parameter_ranges = readRDS("parameter_ranges.Rds")

# This file contains the number of features and entries for every task.
task_metadata = readRDS("task_metadata.Rds")

#' Return a list of parameter definitions. This list contains every necessary parameter for the given algorithm.
#'
#' @param task_id This is `task_id` from the table `run` in the database.
#'
#' @return A named list with one entry for each needed parameter.
get_params_for_algo = function(algo_name) {
  # Load parameter data from pre-saved file "parameter_ranges".
  # See call to readRDS() on top of this file.
    
  if(is.null(parameter_ranges[[algo_name]])) {
    warning(paste0("No parameters found in `parameter_ranges` for algorithm name '", algo_name, "'."))
    return(list())
  } else {
    params = parameter_ranges[[algo_name]]$pars
    
    # We convert the data from some ParamHelper-class to simple JSON.
    params = lapply(params, paramToJSONList)
    
    return(params)
  }
}


#' Requests a list of possible task_ids.
#'
#' @return A vector containing every task_id, which has been evaluated at least once.
get_possible_task_ids = function() {
  all_ids = c()

  for(algo_id in get_algos()) {
    sql.exp = sprintf("SELECT DISTINCT task_id FROM `%s`;", algo_id)
    r = dbGetQuery(con, sql.exp)
    all_ids = c(all_ids, r$task_id)
  }

  return(unique(all_ids))
}


#' Checks if the supplied parameter list is correct according to the data stored in parameter_ranges.
#'
#' @param algo_name The algorithm name these parameters belong to
#' @param params A named list containing the parameters and their values
#'
#' @return TRUE, on success and a named list containing $error, on failure
is_parameter_list_ok = function(algo_name, params) {
  assertChoice(algo_name, names(parameter_ranges))
  par_set = parameter_ranges[[algo_name]]
  
  res = tryCatch(isFeasible(par_set, params), error = as.character)
  if (!isTRUE(res)) {
    return(attr(res, "warning"))
  } else {
    return(TRUE)
  }
}


#' Retrieves metadata about the task from openml.org
#'
#' @param task_id [numeric(n)] The task of interest
#'
#' @return nrow and ncol of the dataset.
get_task_metadata = function(task_id) {
  # Find row in task_metadata
  row = task_metadata[task_metadata$task_id %in% task_id, ]

  if (nrow(row) != length(task_id)) {
    stop(sprintf("The task metadata for task %s has %i results!", paste(task_id, collapse = ","), nrow(row)))
  }

  # Return data
  return(list(nrow = row$instances, ncol = row$features - 1))
}

#' Queries the database for a list of all run parameter configurations with the given algorithm ids, on the given task_id with every parameter in parameter_names.
#'
#' @param algo_ids A vector of algorithm_ids. Typically, this is either one algorithm_id of a specific algorithm implementation or a vector of every algorithm id with a specific name (as acquired by get_algo_ids_for_algo_name(..))
#' @param task_id A single task_id, on which the algorithm has been run.
#'
#' @return A dataframe containing: A column "setup", with the setup_id. A column "<parameter_name>" for every parameter. And one row of data for every setup, that has been run with one of the given algorithms, containing the parameter_data of that run.
get_table = function(algo_id, task_id) {
  sql.exp = sprintf("SELECT * FROM `%s` WHERE task_id = '%s'", algo_id, task_id)
  r = dbGetQuery(con, sql.exp)
  setDT(r)
  # convert columns wiht 0,1 values to logicals
  for(rowname in names(r)) {
    if (all(r[[rowname]] %in% c(0,1))) {
      r[[rowname]] = as.logical(r[[rowname]])
    }
  }
  return(r)
}


#' This returns the inverse-transformation function specified for this parameter.
#'
#' @param algo_name The algorithm name the parameter belongs to.
#' @param param_name The parameter name.
get_inverse_trafo = function(algo_name, param_name) {
  params = get_params_for_algo(algo_name)
  return(params[[param_name]]$trafo.inverse)
}


#' This is the core function of this entire API.
#' It receives a list of algorithm_ids (which will all be treated equally) and a task_id.
#' The parameter list specifies the parameters to "set".
#' We will search the OpenML database for the evaluated parameter set, which has the minimal euclidean distance to our given parameters.
#' We then return the performance of the found point.
#'
#' @param algo_ids A vector of algorithm ids, which will all be treated equally. It is required, that these all have the same name (and parameters).
#' @param task_id A task id, given in numeric form.
#' @param parameters A data table of the form data.table(parA = c(valA1, valA2), parB = c(valB1, valB2))
#'
#' @return A vector of setup ids of the nearest points to the given parameters in the database.
get_nearest_setup = function(algo_id, task_id, parameters) {
  # Table now contains a big dataframe.
  # The rows are all setups run on the task with this algorithm.
  # The columns represent different parameters.
  # The column names represent the parameter name.
  # There are also 5 columns for the 5 evaluation measures.
  table = get_table(algo_id, task_id)
  if (nrow(table) == 0) {
    stop(sprintf("No runs for the combination of learner %s and task %i in the DB", algo_id, task_id))
  }
  
  parameters_trafo = copy(parameters) # will contain parameters trasnformed according to taks

  for(parameter_name in names(parameters_trafo)) {
    # Transform data.independet params that are not defined like in the data base to data.dependent  
    data.trafo = parameter_ranges[[algo_id]]$pars[[parameter_name]]$data.trafo
    if (!is.null(data.trafo)) {
      dict = get_task_metadata(task_id)
      parameters_trafo[[parameter_name]] = data.trafo(dict = dict, par = parameters_trafo)
    }
    
    # Try to apply inverse transformation function, if one is set.
    inverse.trafo = get_inverse_trafo(algo_id, parameter_name)
    
    if(!is.null(inverse.trafo)) {
      table[[parameter_name]] = inverse.trafo(as.numeric(table[[parameter_name]]))
    }
  }
  
  numeric_params = names(parameters_trafo)[sapply(parameters_trafo, is.numeric)]

  # scale table and query to 01
  # mins = sapply(table[, ..numeric_params, drop = FALSE], min, na.rm = TRUE)
  # maxs = sapply(table[, ..numeric_params, drop = FALSE], max, na.rm = TRUE)
  mins = getLower(parameter_ranges[[algo_id]])[numeric_params] #the second subsetting is necessary because we have lowers for numeric params that are not present
  maxs = getUpper(parameter_ranges[[algo_id]])[numeric_params]
  table_trafo_scaled = copy(table)
  tmp = scale(table_trafo_scaled[, ..numeric_params, drop = FALSE], center = mins, scale = maxs - mins)
  table_trafo_scaled[, (numeric_params) := as.data.table(tmp)]
  
  parameters_trafo_scaled = copy(parameters_trafo)
  tmp = scale(as.data.frame(parameters_trafo[, ..numeric_params]), center = mins, scale = maxs - mins)
  parameters_trafo_scaled[, (numeric_params) := as.data.table(tmp)]
  
  # find nearest neighbours
  res = get_nearest_neighbour(table_trafo_scaled, parameters_trafo_scaled, numeric_params)

  res = merge(res[, c("task_id", "rid", "setup", "distance"), with = FALSE], table, all.x = TRUE, all.y = FALSE, sort = FALSE)

  return(res)
}

#' Which algorithms have been run on this task?
#'
#' @param task_id This is `task_id` from the table `run` in the database.
#'
#' @return A named list, containing one entry for each different algorithm name, and the algorithm ids for each algorithm name.
get_algos = function() {
  sql.exp = "SHOW TABLES"
  r = dbGetQuery(con, sql.exp)
  r[[1]]
}

#' Returns a table containing important information on the tasks availiable in the database.
#' 
#' @return [data.frame] 
get_overview_table = function() {
  return(task_metadata)
}

