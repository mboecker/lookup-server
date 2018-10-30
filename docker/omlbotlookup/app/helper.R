library("checkmate")

is_number = function(x) {
  testInt(suppressWarnings(as.numeric(x)))
}

json_error <- function(err_msg, more=list()) {
  c(list(error_message = err_msg), more)
}

get_nearest_neighbour = function(table_trafo_scaled, parameters_trafo_scaled, numeric_params) {

  all_params = names(parameters_trafo_scaled)
  non_numeric_params = setdiff(all_params, c(numeric_params, "api_req_index"))

  parameters_trafo_scaled$api_req_index = seq_len(nrow(parameters_trafo_scaled))

  # has to return list with vectors!
  get_nearest_neighbour_subset = function(parameters_subset, parameters_subset_selection = NULL) {
    if (!is.null(parameters_subset_selection)) {
      table_subset = merge(table_trafo_scaled, parameters_subset_selection, all.x = FALSE)
    } else {
      table_subset = copy(table_trafo_scaled)
    }

    # after subsetting some columns only contain na values
    cols_no_na = names(which(sapply(parameters_subset, function(x) !all(is.na(x)))))
    numeric_params_no_na = intersect(numeric_params, cols_no_na)

    res = FNN::get.knnx(data = table_subset[, ..numeric_params_no_na], query = parameters_subset[, ..numeric_params_no_na], k = 1)

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

# makes sure that characters are converted the right way according to the parameter set
# this is important so that NA becomes eg. NA_integer_
type_save_convert = function(parameters, par_set){
  Map(function(par_vals, par_type) {
    if (par_type %in% getTypeStringsNumeric(include.int = FALSE)) {
      as.numeric(par_vals)
    } else if (par_type %in% getTypeStringsInteger()) {
      as.integer(par_vals)
    } else if (par_type %in% getTypeStringsLogical()) {
      as.logical(par_vals)
    } else if (par_type %in% c(getTypeStringsCharacter(), getTypeStringsDiscrete())) {
      as.character(par_vals)
    }
  }, par_vals = parameters[getParamIds(par_set)], par_type = getParamTypes(par_set))
}

task_ids_paper = function() {
  # Automatic Exploration of Machine Learning Experiments on OpenML
  # Daniel K¨uhn, Philipp Probst, Janek Thomas, Bernd Bischl
  # https://arxiv.org/pdf/1806.10961.pdf
  # table 2
  res = c(3, 31, 37, 43, 49, 219, 3485, 3492, 3493, 3494, 3889, 3891, 3896, 3899, 3902, 3903, 3913, 3917, 3918, 3954, 14965, 10093, 10101, 9980, 9983, 9970, 9971, 9976, 9977, 9978, 9952, 9957, 9967, 9946, 9914, 14966, 34537)
  res[res == 9978] = 145855 # same data_id (1487) but more runs
  return(res)
}