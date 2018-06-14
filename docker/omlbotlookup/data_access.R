library("RMySQL")
library("FNN")
library("memoise")
library("httr")
library("ParamHelpers")
library("data.table")

source("paramToJSONList.R")
source("helper.R")

# Declare database credentials
mysql_username = "root"
mysql_password = ""
mysql_dbname = "openml"
mysql_host = "127.0.0.1"

# Open database connection
con <- dbConnect(MySQL(), user = mysql_username, password = mysql_password, dbname = mysql_dbname, host = mysql_host)


# See /docker/preparation/prepare_parameter_ranges.R for instructions.
# This file contains parameter range data obtained from the omlbot-sourcecode.
parameter_ranges = readRDS("parameter_ranges.Rds")


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
  sql.exp = "SELECT DISTINCT task_id FROM run"
  r = dbGetQuery(con, sql.exp)$task_id
  return(simplify2array(r))
}

#' Which algorithms have been run on this task?
#'
#' @param task_id This is `task_id` from the table `run` in the database.
#'
#' @return A named list, containing one entry for each different algorithm name, and the algorithm ids for each algorithm name.
get_algos_for_task = function(task_id) {
  task_id = as.numeric(task_id)
  
  # This requests every run setup with the given task.
  setup_ids = paste0("SELECT DISTINCT setup FROM run WHERE task_id = ", task_id)
  
  # This requests the input_ids on every of these setups.
  input_ids = paste0("SELECT DISTINCT input_id FROM input_setting WHERE setup IN (", setup_ids, ")")
  
  # This requests the implementation_id to every of these input_ids.
  sql.exp = paste0("SELECT DISTINCT implementation_id, implementation.name, implementation.fullName FROM input INNER JOIN implementation ON implementation.id = input.implementation_id AND input.id IN (", input_ids, ") ORDER BY implementation.name")
  
  # Run query.
  result = dbGetQuery(con, sql.exp)
  
  if(dim(result)[1] == 0) {
    warning("The given task (task_id = ",task_id,") was not found in the database.")
    return(c())
  }
  
  # Group by name.
  d = as.list(aggregate(implementation_id ~ name, result, append, c()))
  return_value = d$implementation_id
  names(return_value) = d$name
  
  # Return in the form list(algo_name = c(impl_id, impl_id, ...), algo_name = ...)
  return(return_value)
}


#' This function returns the algorithm name for the given id
#'
#' @param algo_name The database is searched for this algorithm id.
#'
#' @return The algorithm name fitting to the algorithm id.
get_algo_name_for_algo_id = function(algo_id) {
  algo_id = as.numeric(algo_id)
  
  sql.exp = paste0("SELECT name FROM implementation WHERE id = '", algo_id, "'")
  result = dbGetQuery(con, sql.exp)$name
  
  if(length(result) == 0) {
    warning("There is no algorithm in the database with this id (", algo_id ,").")
    return(NULL)
  }
  
  if(substr(result, start=1, stop = 4) == "mlr.") {
    result = substring(result, first = 5)
  }
  
  return(result)
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
  res = tryCatch(isFeasible(par_set, params), error = function(e) e)
  if (inherits(res, c("try-error", "error"))) {
    as.character(res)
  } else if (!isTRUE(res)) {
    attr(res, "warning")
  } else {
    TRUE
  }
}


#' Retrieves metadata about the task from openml.org
#'
#' @param task_id The task of interest
#'
#' @return nrow and ncol of the dataset.
get_task_metadata = function(task_id) {
  url = paste0("https://www.openml.org/api/v1/json/data/qualities/", task_id)
  ret = httr::GET(url, httr::accept_json())
  
  # No such task
  if(httr::status_code(ret) != 200) {
    return(NULL)
  }
  
  # Re-format data
  res = httr::content(ret)
  qualities = as.list(BBmisc::extractSubList(res$data_qualities$quality, "value"))
  names(qualities) = BBmisc::extractSubList(res$data_qualities$quality, "name")
  
  # Extract data
  nrow = as.numeric(qualities$NumberOfInstances)
  ncol = as.numeric(qualities$NumberOfFeatures) - 1
  
  # Return data
  return(list(nrow = nrow, ncol = ncol))
}

get_cached_task_metadata = memoise(get_task_metadata, cache = cache_filesystem("~/cache_omlbotlookup"))

#' Queries the database for a list of all run parameter configurations with the given algorithm ids, on the given task_id with every parameter in parameter_names.
#'
#' @param algo_id Algorithm id (eg. 'mlr.classif.ranger')
#' @param task_id A single task_id, on which the algorithm has been run.
#' @param parameter_names A vector or list of 
#'
#' @return A dataframe containing: A column "setup", with the setup_id. A column "<parameter_name>" for every parameter. And one row of data for every setup, that has been run with one of the given algorithms, containing the parameter_data of that run.
get_parameter_table = function(algo_id, task_id, parameter_names) {
  
  # generates something like this
  #
  # SELECT run.setup, tbl_params.name AS paramname, MAX(input_setting.value) as value
  # FROM run 
  # JOIN (
  #   SELECT DISTINCT input.name from input INNER JOIN implementation ON implementation.id = input.implementation_id WHERE implementation.name = 'mlr.classif.ranger' AND input.name NOT LIKE 'openml%'
  # ) AS tbl_params
  # INNER JOIN input ON tbl_params.name = input.name
  # LEFT JOIN input_setting ON input.id = input_setting.input_id AND input_setting.setup = run.setup
  # WHERE run.task_id = 3
  # GROUP BY run.setup, tbl_params.name;
  
  # NOTES:
  # Due to the LEFT JOIN we will get many paramnames with NA values and usually for one paramname only one value that is not NA.
  # With MAX and the grouping we drop all NAs for ine paramname value and setup pair. If only NAs exist they remain.
  
  parameter_names_string = paste0("'", parameter_names, "'", collapse = ",")
  task_id = 3
  sql.exp = paste0("SELECT run.setup, tbl_params.name AS paramname, MAX(input_setting.value) as value
              FROM run 
              JOIN (
                SELECT DISTINCT input.name from input INNER JOIN implementation ON implementation.id = input.implementation_id WHERE implementation.name = '", algo_id, "' AND input.name IN (", parameter_names_string, ")
              ) AS tbl_params
              INNER JOIN input ON tbl_params.name = input.name
              LEFT JOIN input_setting ON input.id = input_setting.input_id AND input_setting.setup = run.setup
              WHERE run.task_id = ", task_id, "
              GROUP BY run.setup, tbl_params.name;")

  system.time({result = dbGetQuery(con, sql.exp)})
  setDT(result)
  setkeyv(result, "setup")
  dt.na = result[, list(all.na = all(is.na(value))), by = .(setup)]
  result = result[dt.na[all.na == FALSE,], ]
  resultd = dcast(result, setup~paramname)
  return(resultd)
}

get_cached_parameter_table = memoise(get_parameter_table, cache = cache_filesystem("~/cache_omlbotlookup"))


#' Returns the default value for the given parameter on the given task
#'
#' @param algo_name The algorithm name the parameter belongs to.
#' @param param_name The parameter name.
get_parameter_default = function(algo_name, param_name) {
  params = get_params_for_algo(algo_name)
  def = params[[param_name]]$default
  return(def)
}


#' This returns the inverse-transformation function specified for this parameter.
#'
#' @param algo_name The algorithm name the parameter belongs to.
#' @param param_name The parameter name.
get_inverse_trafo = function(algo_name, param_name) {
  params = get_params_for_algo(algo_name)
  return(params[[param_name]]$trafo.inverse)
}


#' This replaces every NA in the given table with the correct default value.
#'
#' @param table The parameter table, as generated by get_parameter_table(...)
#' @param algo_name The algorithm name the parameters belong to.
#' @param param_names The parameter names as a vector.
#' @param task_id This is sometimes needed, because some defaults are data-dependent.
replace_na_with_defaults = function(table, algo_name, parameter_names) {
  
  for(parameter_name in parameter_names) {
    nas = is.na(table[[parameter_name]])
    if(any(nas)) {
      def = get_parameter_default(algo_name, parameter_name)
      if (!is.null(def)) {
        table[[parameter_name]][nas] = def
      }
    }
  }
  
  cc = complete.cases(table)
  
  cat(sprintf("Removing %f%% (%d/%d) of runs, because they had missing values.\n", (sum(!cc) * 100.0 / dim(table)[1]), sum(!cc), dim(table)[1]))
  
  table = table[cc,]
  
  return(table)
}


#' This is the core function of this entire API.
#' It receives a list of algorithm_ids (which will all be treated equally) and a task_id.
#' The parameter list specifies the parameters to "set".
#' We will search the OpenML database for the evaluated parameter set, which has the minimal euclidean distance to our given parameters.
#' We then return the performance of the found point.
#'
#' @param algo_id Algorithm id (eg. 'mlr.classif.ranger')
#' @param task_id A task id, given in numeric form.
#' @param parameters A data frame of the form data.frame(parA = c(valA1, valA2), parB = c(valB1, valB2))
#'
#' @return A vector of setup ids of the nearest points to the given parameters in the database.
get_nearest_setups = function(algo_id, algo_name, task_id, parameters) {
  # Table now contains a big dataframe.
  # The rows are all setups run on the task with this algorithm.
  # The columns represent different parameters.
  # The column names represent the parameter name.
  table = get_cached_parameter_table(algo_id, task_id, names(parameters));
  
  if(is.null(table)) {
    return(list(error = "No suitable points found."))
  }
  
  # Fill in defaults for NAs
  table = replace_na_with_defaults(table, algo_name, names(parameters))
  
  for(parameter_name in names(parameters)) {
    
    # Transform data.independet params that are not defined like in the data base to data.dependent  
    data.trafo = parameter_ranges[[algo_name]]$pars[[parameter_name]]$data.trafo
    if (!is.null(data.trafo)) {
      dict = get_cached_task_metadata(task_id)
      parameters[[parameter_name]] = data.trafo(dict = dict, par = parameters)
    }
    
    # Try to apply inverse transformation function, if one is set.
    inverse.trafo = get_inverse_trafo(algo_name, parameter_name)
    
    if(!is.null(inverse.trafo)) {
      table[[parameter_name]] = inverse.trafo(as.numeric(table[[parameter_name]]))
    }
    
    if(!is.numeric(parameters[[parameter_name]])) {
      # We subset the table to remove the factorial parameters, which are not equal to the request.
      table = table[table[[parameter_name]] == parameters[[parameter_name]],]
      
      # As the "distance" to this parameter has been "evaluated", we can remove it from the table, because we can't sort by it.
      table[[parameter_name]] = NULL
    }
  }

  # No suitable points were found.
  if(dim(table)[1] == 0) {
    return(list(error = "No suitable points were found."))
  }

  # Remove NAs
  table = table[complete.cases(table), , drop = FALSE]

  query = parameters[names(table)[-1]]

  # scale table and query to 01
  mins = sapply(table[, -1, drop = FALSE], min)
  maxs = sapply(table[, -1, drop = FALSE], max)
  table.scaled = scale(table[, -1, drop = FALSE], center = mins, scale = maxs - mins)
  table[, 2:ncol(table)] = table.scaled
  query = as.data.frame(scale(query, center = mins, scale = maxs - mins))

  # find nearest neighbour
  
  res = FNN::get.knnx(data = table[, -1, drop = FALSE], query = query, k = 1)
  
  distances = res$nn.dist[, 1, drop = TRUE]
  setup = table[res$nn.index[, 1, drop = TRUE], , drop = FALSE]

  return(data.frame(setup_ids = setup$setup, distances = distances))
}


#' Get data associated with runs of setup "setup_ids" on task "task_id"
#'
#' @param task_id The task these setups were run on.
#' @param setup_ids The setup ids of interest.
#'
#' @return A list, with names equal to the setup ids.
get_setup_data = function(task_id, setup_ids) {
  sql.exp = paste0("SELECT setup, input.implementation_id, input.name, input_setting.value
                    FROM input_setting JOIN input ON input.id = input_setting.input_id
                    WHERE setup IN (",paste0(setup_ids,collapse=", "),")")
  result = dbGetQuery(con, sql.exp)

  return_value = lapply(setup_ids, function(setup_id) {
    rows = result[result$setup == setup_id, -1, drop = FALSE]
    impl_id = rows[[1]][1]
    algo_name = get_algo_name_for_algo_id(impl_id)
    params = as.list(rows$value)
    names(params) = rows$name

    # Remove openml. parameters
    params = params[substr(names(params), start = 1, stop = 7) != "openml."]
    
    # Find out which parameters are not present in the database
    needs_default_names = parameter_ranges[[algo_name]]$pars
    needs_default_names[names(params)] = NULL
    needs_default_names = names(needs_default_names)

    # Get default values for these parameters
    default_values = lapply(needs_default_names, function(param_name) {
      get_parameter_default(algo_name, param_name)
    })
    names(default_values) = needs_default_names 
    
    # Add defaults
    params = append(params, default_values)
    
    for (i in seq_along(params)) {
      if (is.character(params[[i]])) params[[i]] = type.convert(params[[i]])  
    }
    
    # Now, we request performance data on the nearest point given by the database.
    sql.exp = paste0("SELECT evaluation.source, function_id, value FROM evaluation JOIN run ON run.rid = evaluation.source WHERE task_id = ", task_id, " AND setup = ", setup_id, " AND function_id IN (4,45,54,59,63) ORDER BY function_id")
    result = dbGetQuery(con, sql.exp)
    
    n_func_ids = dim(result)[1];
    
    if(n_func_ids < 4) {
      stop("Less than 4 function ids!")
    }
    
    if(n_func_ids == 4) {
      function_names = c("auc","accuracy","rmse","runtime")
    } else {
      function_names = c("auc","accuracy","rmse","scimark","runtime")
    }
     
    rid = result$source[1]
    performance_data = as.list(result$value)
    names(performance_data) = function_names

    return(c(list(impl_id = impl_id, run_id = rid, performance = performance_data), params))
  })

  return_value = do.call(rbind, return_value)
  
  return(return_value)
}
