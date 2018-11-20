#' This is the core function of this entire API.
#' It receives a list of algorithm_ids (which will all be treated equally) and a task_id.
#' The parameter list specifies the parameters to "set".
#' We will search the OpenML database for the evaluated parameter set, which has the minimal euclidean distance to our given parameters.
#' We then return the performance of the found point.
#'
#' @param learner_ids A vector of algorithm ids, which will all be treated equally. It is required, that these all have the same name (and parameters).
#' @param task_id A task id, given in numeric form.
#' @param parameters A data table of the form data.table(parA = c(valA1, valA2), parB = c(valB1, valB2))
#'
#' @return A vector of setup ids of the nearest points to the given parameters in the database.
get_nearest_setup = function(learner_id, task_id, parameters) {
  # Table now contains a big dataframe.
  # The rows are all setups run on the task with this algorithm.
  # The columns represent different parameters.
  # The column names represent the parameter name.
  # There are also 5 columns for the 5 evaluation measures.
  table = get_runs(learner_id, task_id)
  if (nrow(table) == 0) {
    stop(sprintf("No runs for the combination of learner %s and task %i in the DB", learner_id, task_id))
  }
  
  parameters_trafo = copy(parameters) # will contain parameters trasnformed according to taks

  for(parameter_name in names(parameters_trafo)) {
    # Transform data.independet params that are not defined like in the data base to data.dependent  
    data.trafo = parameter_ranges[[learner_id]]$pars[[parameter_name]]$data.trafo
    if (!is.null(data.trafo)) {
      dict = get_task_metadata(task_id)
      parameters_trafo[[parameter_name]] = data.trafo(dict = dict, par = parameters_trafo)
    }
    
    # Try to apply inverse transformation function, if one is set.
    inverse.trafo = get_inverse_trafo(learner_id, parameter_name)
    
    if(!is.null(inverse.trafo)) {
      table[[parameter_name]] = inverse.trafo(as.numeric(table[[parameter_name]]))
    }
  }
  
  numeric_params = names(parameters_trafo)[sapply(parameters_trafo, is.numeric)]

  # scale table and query to 01
  # mins = sapply(table[, ..numeric_params, drop = FALSE], min, na.rm = TRUE)
  # maxs = sapply(table[, ..numeric_params, drop = FALSE], max, na.rm = TRUE)
  mins = getLower(parameter_ranges[[learner_id]])[numeric_params] #the second subsetting is necessary because we have lowers for numeric params that are not present
  maxs = getUpper(parameter_ranges[[learner_id]])[numeric_params]
  table_trafo_scaled = copy(table)
  tmp = scale(table_trafo_scaled[, numeric_params, drop = FALSE, with = FALSE], center = mins, scale = maxs - mins)
  table_trafo_scaled[, (numeric_params) := as.data.table(tmp)]
  
  parameters_trafo_scaled = copy(parameters_trafo)
  tmp = scale(as.data.frame(parameters_trafo[, numeric_params, with = FALSE]), center = mins, scale = maxs - mins)
  parameters_trafo_scaled[, (numeric_params) := as.data.table(tmp)]
  
  # find nearest neighbours
  res = get_nearest_neighbor(table_trafo_scaled, parameters_trafo_scaled, numeric_params)

  #res = merge(res[, c("task_id", "rid", "setup", "distance"), with = FALSE], table, all.x = TRUE, all.y = FALSE, sort = FALSE)

  return(res)
}