#' Returns the task ids, which are saved in the database and can be queried.
#'
#' @return A vector of task ids.
#' @param restrict [logical]
#'   Restrict the tasks to those that appear in the following paper:
#'   Automatic Exploration of Machine Learning Experiments on OpenML
#'   Daniel K¨uhn, Philipp Probst, Janek Thomas, Bernd Bischl
#'   https://arxiv.org/pdf/1806.10961.pdf
#' @export
getAvailableTasks = function(restrict = FALSE) {
  assertFlag(restrict)
  httr.res = httr::GET(paste0(omlTuneBenchR$connection, "/tasks"), query = list(restrict = restrict), httr::accept_json())
  res = httr::content(httr.res)
  if (!is.null(res$error)) {
    stop(res$error)
  } else {
    return(simplify2array(res$possible_task_ids))
  }
}
