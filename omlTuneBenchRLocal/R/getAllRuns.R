#' @title Gets table with all runs
#'
#' @description
#' Gets table with all runs for a given learner and task.
#' If the runs are not available locally in `omlTuneBenchR$rdspath` they will be downloaded from `omlTuneBenchR$remote` first.
#'
#' @param learner_id (`character(1)`)
#'   The learner (e.g. `"classif.rpart"`)
#' @param task_id (`integer(1)`)
#'   The task_id (e.g. `3`)
#' @return `data.frame`
#' @export
getAllRuns = function(learner_id, task_id) {
  file = sprintf("rdsdata/data_%s_%i.rds", learner_id, task_id)
  rdsfile = fs::path_join(omlTuneBenchR$rdspath, file)
  if (!fs::file_exists(rdsfile)) {
    url = sprintf("%s/%s", omlTuneBenchR$remote, file)
    download.file(url, destfile = rdsfile)
  }
  readRDS(rdsfile)
}