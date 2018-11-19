#' @import smoof
#' @import ParamHelpers
#' @import checkmate
#' @importFrom stats setNames
#' @importFrom utils download.file

omlTuneBenchR = new.env()
omlTuneBenchR$remote = "https://www.statistik.tu-dortmund.de/~richter/omltunebenchr"

.onLoad = function(libname, pkgname) {
  omlTuneBenchR$parameter_ranges = readRDS(system.file("parameter_ranges.Rds", package = "omlTuneBenchR"))
  omlTuneBenchR$task_metadata = readRDS(system.file("task_metadata.Rds", package = "omlTuneBenchR"))

  # set path to store rds files
  omlTuneBenchR$rdspath = Sys.getenv("OML_TUNE_BENCH_RDSPATH") %??% "~/omlTuneBenchR/"
  config.file = "~/.config/omlTuneBenchRLocal.R"
  if (fs::file_exists(config.file)) {
    sys.source(config.file, envir = omlTuneBenchR)
  }
}
