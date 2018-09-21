#' @title Download all runs
#'
#' @description
#' Download all runs
#'
#' @param learner.name (`character(1)`)
#'   The learner (e.g. `"classif.rpart"`)
#' @param task.id (`integer(1)`)
#'   The task id (e.g. `3`)
#' @return `data.frame`
#' @export
getAllRuns = function(learner.name, task.id) {
  tfile = tempfile()
  url = sprintf("%s/rds?task=%s&algo=%s", omlTuneBenchR$connection, task.id, learner.name)
  download.file(url, destfile = tfile)
  readRDS(tfile)
}