get_nearest_neighbor = function(table_trafo_scaled, parameters_trafo_scaled, numeric_params) {

  all_params = names(parameters_trafo_scaled)
  non_numeric_params = setdiff(all_params, c(numeric_params, "api_req_index"))

  parameters_trafo_scaled$api_req_index = seq_len(nrow(parameters_trafo_scaled))

  # has to return list with vectors!
  get_nearest_neighbour_subset = function(parameters_subset, parameters_subset_selection = NULL) {
    if (!is.null(parameters_subset_selection)) {
      table_subset = merge(table_trafo_scaled, parameters_subset_selection, by = names(parameters_subset_selection))
    } else {
      table_subset = copy(table_trafo_scaled)
    }

    # after subsetting some columns only contain na values
    cols_no_na = names(which(sapply(parameters_subset, function(x) !all(is.na(x)))))
    numeric_params_no_na = intersect(numeric_params, cols_no_na)

    res = FNN::get.knnx(data = table_subset[, numeric_params_no_na, with = FALSE], query = parameters_subset[, numeric_params_no_na, with = FALSE], k = 1)

    # remove matrix strucutre because we only use k=1
    res = lapply(res, function(x) x[, 1, drop = TRUE])

    # return complete table
    c(as.list(table_subset[res$nn.index, ]), list(distance = res$nn.dist))
  }

  # call get_nearest_neighbour_subset for the table subset with only the numeric params for each combination of non numeric params
  if (length(non_numeric_params)>0) {
    nnres = parameters_trafo_scaled[, c(list(api_req_index = api_req_index), get_nearest_neighbour_subset(.SD, mget(non_numeric_params))), by = non_numeric_params]
    nnres = nnres[, !"api_req_index"] 
  } else {
    nnres = as.data.table(get_nearest_neighbour_subset(parameters_trafo_scaled))
  }
  return(nnres)
}