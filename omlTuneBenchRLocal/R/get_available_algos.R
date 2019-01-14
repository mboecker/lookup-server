#' Returns the algo ids for which there are entries in the database.
#'
#' @return A vector of algo ids.
#' @export
get_available_algos = function() {
  colnames(task_metadata)[grep("^classif", colnames(task_metadata))]
}
