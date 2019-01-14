#' Returns the task_ids, which are saved in the database and can be queried.
#'
#' @return A vector of task_ids.
#' @param restrict [logical]
#'   Restrict the tasks to those that appear in the following paper:
#'   Automatic Exploration of Machine Learning Experiments on OpenML
#'   Daniel K¨uhn, Philipp Probst, Janek Thomas, Bernd Bischl
#'   https://arxiv.org/pdf/1806.10961.pdf
#' @export
get_available_tasks = function(restrict = FALSE) {
  if (restrict) {
    unique(task_metadata[get("data_in_paper") == TRUE,]$task_id)
  } else {
    unique(task_metadata$task_id)
  }
}
