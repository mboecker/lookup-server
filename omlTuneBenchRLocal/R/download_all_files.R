#' @title Downloads all available run files
#' @description Downloads all available run files to the path specified in `omlTuneBenchR$rdspath`.
#' @param overwrite  `logical(1)`
#'   Overwrite files or just download missing files?
#' @param restrict `logical(1)`
#'   Restrict to tasks from paper?
#' @return `logical(1)`
#' @export
download_all_files = function(overwrite = TRUE, restrict = TRUE) {
  learners = get_available_algos()
  tasks = get_available_tasks(restrict = restrict)
  res = purrr::cross(list(learner_id = learners, task_id = tasks))
  purrr::walk(res, purrr::lift(get_runs))
  invisible(TRUE)
}
