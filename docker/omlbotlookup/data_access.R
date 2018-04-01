library("RMySQL")
library("FNN")
library("memoise")

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

  # Algorithm names in the database have a leading "mlr." in front of their name.
  # We delete this.
  if (substring(algo_name, 1, 4) == "mlr.") {
    algo_name = substring(algo_name, 5)
  }
    
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

#' In the database, each new version of a classification algorithm has a different algo_id.
#' This function returns every algo_id fitting to a given algo_name.
#'
#' @param algo_name The database is searched for this algorithm name.
#'
#' @return A vector containing every algo_id that fits to algo_name.
get_algo_ids_for_algo_name = function(algo_name) {
  # Escape algorithm name.
  algo_name = dbEscapeStrings(con, as.character(algo_name))
  
  # Request every fitting algo_id.
  sql.exp = paste0("SELECT id FROM implementation WHERE name = '", algo_name, "'")
  result = dbGetQuery(con, sql.exp)$id
  
  # If there is no result, return an empty vector.
  if(length(result) == 0) {
    warning("There is no algorithm in the database with this name ('", algo_name, "').")
    return(c())
  }
  
  return(as.numeric(result))
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
  }
  
  return(result)
}

#' Queries the database for a list of all run parameter configurations with the given algorithm ids, on the given task_id with every parameter in parameter_names.
#'
#' @param algo_ids A vector of algorithm_ids. Typically, this is either one algorithm_id of a specific algorithm implementation or a vector of every algorithm id with a specific name (as acquired by get_algo_ids_for_algo_name(..))
#' @param task_id A single task_id, on which the algorithm has been run.
#' @param parameter_names A vector or list of 
#'
#' @return A dataframe containing: A column "setup", with the setup_id. A column "<parameter_name>" for every parameter. And one row of data for every setup, that has been run with one of the given algorithms, containing the parameter_data of that run.
get_parameter_table = function(algo_ids, task_id, parameter_names) {
  impl_ids_as_string = paste0(algo_ids, collapse = ", ")
  
  # generate_sql_query = function() {
  #   generate_parameter_query = function(parameter_name) {
  #     paste0("SELECT DISTINCT input_setting.setup, input_setting.value AS `", parameter_name, "`
  #                     FROM input
  #                     JOIN input_setting ON input_setting.input_id = input.id
  #                     JOIN run ON run.setup = input_setting.setup
  #                     WHERE input.name = '", parameter_name,"'
  #                     AND task_id = ", task_id, "
  #                     AND uploader = 2702
  #                     AND input.implementation_id IN (", impl_ids_as_string ,")")
  #   }
  #   selects = paste0("`" ,parameter_names, "`", collapse = ", ")
  #   inner_selects = sapply(parameter_names, generate_parameter_query)
  #   inner_selects = paste0("(", inner_selects, ") AS p", seq_len(length(inner_selects)))
  #   inner_selects[-1] = paste0(inner_selects[-1], " ON p",1:(length(inner_selects)-1),".setup = p",2:length(inner_selects),".setup")
  #   inner_selects = paste0(inner_selects, collapse = " JOIN ")
  #   paste0("SELECT p1.setup, ", selects, " FROM ", inner_selects)
  # }
  
  # TODO:
  # Replace the code below with one query instead of |parameter_names| queries.
  # 
  # Example:
  # SELECT p1.setup, `mtry`, `num.trees` FROM 
  #   (SELECT DISTINCT input_setting.setup, input_setting.value AS `mtry`` FROM input JOIN input_setting ON input_setting.input_id = input.id JOIN run ON run.setup = input_setting.setup WHERE input.name = "mtry" AND task_id = 3 AND uploader = 2702) AS p1
  # JOIN
  #   (SELECT DISTINCT input_setting.setup, input_setting.value AS `num.trees` FROM input JOIN input_setting ON input_setting.input_id = input.id JOIN run ON run.setup = input_setting.setup WHERE input.name = "num.trees" AND task_id = 3 AND uploader = 2702) AS p2
  # ON p1.setup = p2.setup;

  # For each parameter (each entry of `parameters`), run one query against the database to retrieve every evaluated parameter configuration for this parameter.
  # Save the results in a list (lapply).
  db_entries = lapply(parameter_names, function(parameter_name) {
    sql.exp = paste0("SELECT DISTINCT input_setting.setup, input_setting.value AS `", parameter_name, "`
                      FROM input
                      JOIN input_setting ON input_setting.input_id = input.id
                      JOIN run ON run.setup = input_setting.setup
                      WHERE input.name = '", parameter_name,"'
                      AND task_id = ", task_id, "
                      AND uploader = 2702
                      AND input.implementation_id IN (", impl_ids_as_string ,");")
    result = dbGetQuery(con, sql.exp)
    result
  })
  
  if(length(db_entries) == 0) {
    return(NULL)
  }
  
  # Merge results by same setup_ids
  # FIXME: replace for loop by better merge...
  if(length(db_entries) >= 2) {
    table = merge(db_entries[[1]], db_entries[[2]], all = TRUE, by = "setup")
    
    if(length(db_entries) >= 3) {
      for (i in 3:length(db_entries)) {
        table = merge(table, db_entries[[i]], all = TRUE, by = "setup")
      }
    }
  } else {
    table = db_entries[[1]]
  }
  
  return(table)
}

get_cached_parameter_table = memoise(get_parameter_table)

get_parameter_default = function(algo_name, param_name) {
  params = get_params_for_algo(algo_name)
  return(params[[param_name]]$default)
}

get_inverse_trafo = function(algo_name, param_name) {
  params = get_params_for_algo(algo_name)
  return(params[[param_name]]$trafo.inverse)
}

replace_na_with_defaults = function(table, algo_name, parameter_names) {
  for(parameter_name in parameter_names) {
    
    nas = is.na(table[[parameter_name]])
    if(any(nas)) {
      def = get_parameter_default(algo_name, parameter_name)
      if (is.null(def)) {
        warning(paste0("NA found in parameter table without a default! (Parameter name: ",parameter_name,")"))
        return(NULL)
      } else {
        table[[parameter_name]][nas] = def
      }
    }
  }
  
  return(table)
}

#' This is the core function of this entire API.
#' It receives a list of algorithm_ids (which will all be treated equally) and a task_id.
#' The parameter list specifies the parameters to "set".
#' We will search the OpenML database for the evaluated parameter set, which has the minimal euclidean distance to our given parameters.
#' We then return the performance of the found point.
#'
#' @param algo_ids A vector of algorithm ids, which will all be treated equally. It is required, that these all have the same name (and parameters).
#' @param task_id A task id, given in numeric form.
#' @param parameters A named list of the form list(parameter_name = parameter_value, parameter_name = parameter_value)
#'
#' @return A vector of setup ids of the nearest points to the given parameters in the database.
get_nearest_setup = function(algo_ids, algo_name, task_id, parameters) {
  # Table now contains a big dataframe.
  # The rows are all setups run on the task with this algorithm.
  # The columns represent different parameters.
  # The column names represent the parameter name.
  table = get_cached_parameter_table(algo_ids, task_id, names(parameters));
  
  if(is.null(table)) {
    return(list(error = "No suitable points found."))
  }
  
  # Fill in defaults for NAs
  table = replace_na_with_defaults(table, algo_name, names(parameters));
  if(is.null(table)) {
    return(list(error = "NA found in parameter table without a default!"))
  }
  
  # Calculate euclidean distance for every row
  for(parameter_name in names(parameters)) {
    
    # Try to apply inverse transformation function, if one is set.
    inverse.trafo = get_inverse_trafo(algo_name, parameter_name)
    if(!is.null(inverse.trafo)) {
      parameters[[parameter_name]] = inverse.trafo(as.numeric(parameters[[parameter_name]]))
      table[[parameter_name]] = inverse.trafo(as.numeric(table[[parameter_name]]))
    }
    
    if(!is_number(parameters[[parameter_name]])) {
      # We subset the table to remove the factorial parameters, which are not equal to the request.
      table = table[table[[parameter_name]] == parameters[[parameter_name]],]
      
      # As the "distance" to this parameter has been "evaluated", we can remove it from the table, because we can't sort by it.
      table[[parameter_name]] = NULL
    }
  }

  # No suitable points were found.
  if(dim(table)[1] == 0) {
    return(NULL)
  }

  # Remove NAs
  table = table[complete.cases(table),]
  
  # scale all values to 0-1
  #table[, -1] = apply(table[,-1,drop=F], MARGIN = 2, FUN = function(X) { X = as.numeric(X); (X - min(X))/diff(range(X)) } )
  
  # find nearest neighbour
  data = apply(data.matrix(table[,-1]), 2, as.numeric)
  query = as.numeric(parameters[names(table)[-1]])
  res = FNN::get.knnx(data = data, query = t(query), k = 1)
  
  nearest_distance = res$nn.dist[1,1] #FIXME: We also want to return this value, right?
  setup_ids = table[res$nn.index[1,1], "setup"];

  return(list(nearest_setup = setup_ids))
}

get_setup_data = function(setup_ids) {
  sql.exp = paste0("SELECT setup, input.implementation_id, input.name, input_setting.value
                    FROM input_setting JOIN input ON input.id = input_setting.input_id
                    WHERE setup IN (",paste0(setup_ids,collapse=", "),")")
  result = dbGetQuery(con, sql.exp)
  
  # Re-format data
  return_value = as.list(unique(result$setup))
  names(return_value) = unique(result$setup)
  
  return_value = lapply(return_value, function(setup_id) {
    rows = result[result$setup == setup_id,-1]
    impl_id = rows[[1]][1]
    params = as.list(rows$value)
    names(params) = rows$name
    return(list(impl_id = impl_id, params = params))
  })
  
  return(return_value)
}
