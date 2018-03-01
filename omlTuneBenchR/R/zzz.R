#' @import smoof
#' @import ParamHelpers
#' @import checkmate
#' @import httr

omlTuneBenchR = new.env(parent = emptyenv())
omlTuneBenchR$debug = FALSE
omlTuneBenchR$adress.default = "localhost:8746"
omlTuneBenchR$adress = NULL # values different from NULL mena that the server is started and reachable under this adress

.onLoad = function(libname, pkgname) {
  if (requireNamespace("debugme", quietly = TRUE) && "omlTuneBenchR" %in% strsplit(Sys.getenv("DEBUGME"), ",", fixed = TRUE)[[1L]]) {
    debugme::debugme()
    omlTuneBenchR$debug = TRUE
  }
}
