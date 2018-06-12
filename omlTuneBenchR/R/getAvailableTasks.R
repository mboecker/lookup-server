#' Returns the task ids, which are saved in the database and can be queried.
#'
#' @return A vector of task ids.
#' @export
getAvailableTasks = function() {
  httr.res = httr::GET(paste0(omlTuneBenchR$connection, "/tasks"), httr::accept_json())
  res = httr::content(httr.res)
  if (!is.null(res$error)) {
    stop(res$error)
  } else {
    return(simplify2array(res$possible_task_ids))
  }
}
