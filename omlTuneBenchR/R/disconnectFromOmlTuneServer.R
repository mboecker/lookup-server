#' @title Disconnects from a OmlTuneServer.
#' @description Resets the connection to a OmlTuneServer.
#' @return `logical(1)`
#' @export

disconnectFromOmlTuneServer = function() {
  if (is.null(omlTuneBenchR$connection)) {
    stop ("No connection to disconnect from!")
  } else {
    omlTuneBenchR$connection = NULL
    invisible(TRUE)
  }
}
