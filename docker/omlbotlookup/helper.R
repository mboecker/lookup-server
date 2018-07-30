library("checkmate")

is_number = function(x) {
  testInt(suppressWarnings(as.numeric(x)))
}

json_error <- function(err_msg, more=list()) {
  append(list(error_message = err_msg), more)
}

get_nearest_neighbour = function(table_scaled, parameters_trafo_scaled, numeric_params) {

  all_params = names(parameters_trafo_scaled)
  non_numeric_params = setdiff(all_params, numeric_params)

  # iterate over as subsets
  # TODO
  get_nearest_neighbour_subset(table_scaled[t_subset, ..numeric_params], parameters_subset[p_subset, numeric_params, drop = FALSE])
  
  # combine subset results
  # TODO

}

get_nearest_neighbour_subset = function(table_subset, parameters_subset) {
  res = FNN::get.knnx(data = table_subset, query = parameters_subset, k = 1)
  return(res)
}