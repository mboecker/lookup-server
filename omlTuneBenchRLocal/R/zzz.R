#' @import smoof
#' @import ParamHelpers
#' @import checkmate
#' @import data.table
#' @importFrom stats setNames
#' @importFrom utils download.file
#' @importFrom utils object.size

omlTuneBenchR = new.env()
omlTuneBenchR$remote = "https://www.statistik.tu-dortmund.de/~richter/omltunebenchr"
omlTuneBenchR$rdspath = path.expand("~/omlTuneBenchR/")
omlTuneBenchR$cache_size = 512 #MB
omlTuneBenchR$cache_table = data.table(learner_id = character(0), task_id = integer(0), last_accessed = .POSIXct(double(0)), data = list())

.onLoad = function(libname, pkgname) {
  #omlTuneBenchR$parameter_ranges = paramater_ranges
  #omlTuneBenchR$task_metadata = task_metadata

  # set path to store rds files
  config.file = "~/.config/omlTuneBenchRLocal.R"
  if (fs::file_exists(config.file)) {
    sys.source(config.file, envir = omlTuneBenchR)
  }
}
