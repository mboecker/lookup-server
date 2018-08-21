#' Returns the algo ids for which there are entries in the database.
#'
#' @return A vector of algo ids.
#' @export
getAvailableAlgos = function() {
  httr.res = httr::GET(paste0(omlTuneBenchR$connection, "/algos"), httr::accept_json())
  res = httr::content(httr.res)
  if (!is.null(res$error)) {
    stop(res$error)
  } else {
    return(simplify2array(res$possible_algo_ids))
  }
}
