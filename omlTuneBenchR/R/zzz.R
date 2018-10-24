#' @import smoof
#' @import ParamHelpers
#' @import checkmate
#' @import httr
#' @import jsonlite
#' @importFrom stats setNames
#' @importFrom utils download.file

omlTuneBenchR = new.env(parent = emptyenv())
omlTuneBenchR$debug = FALSE
omlTuneBenchR$adress.default = "http://localhost:8746"
omlTuneBenchR$adress = NULL # values different from NULL mena that the server is started and reachable under this adress

.onLoad = function(libname, pkgname) {
  if (requireNamespace("debugme", quietly = TRUE) && "omlTuneBenchR" %in% strsplit(Sys.getenv("DEBUGME"), ",", fixed = TRUE)[[1L]]) {
    debugme::debugme()
    omlTuneBenchR$debug = TRUE
  }
  omlTuneBenchR$parameter_ranges = readRDS(system.file("docker/omlbotlookup/app/parameter_ranges.Rds", package = "omlTuneBenchR"))
}
