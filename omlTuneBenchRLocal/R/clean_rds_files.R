#' @title Cleans all RDS Files
#' @description Cleans all RDS Files stored in `omlTuneBenchR$rdspath`.
#' @return `logical(1)`
#' @export

clean_rds_files = function() {
  if (!fs::dir_exists(omlTuneBenchR$rdspath)) {
    stop(sprintf("Directory %s does not exist!", omlTuneBenchR$rdspath))
  } else {
    fs::dir_delete(omlTuneBenchR$rdspath)
    message(sprintf("Directory %s deleted.", omlTuneBenchR$rdspath))
  }
}
