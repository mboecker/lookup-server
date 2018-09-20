#' @title Connect to a running OmlTuneServer.
#' @description Establishes a connection to a runnign OmlTuneServer.
#' @param adress (`character(1)`)
#'   The URL where we can reach the API (e.g. `http://localhost:8746`)
#' @param timeout (`integer(1)`)
#'   How many seconds should we wait until we await a response.
#'   After stating the server it can take a while until it's reachable.
#' @return `logical(1)`
#' @export

connectToOmlTuneServer = function(adress = NULL, timeout = 10L) {
  assertString(adress, null.ok = TRUE)
  assertInt(timeout, lower = 0)
  adress = adress %??% omlTuneBenchR$adress.default
  
  if (!checkIfTuneServerIsUp(adress, timeout)) {
    stop(sprintf("Server is not reachable under %s", adress))
  }
  # finish as soon as docker is sucessfully and ready to receive
  omlTuneBenchR$connection = adress
  invisible(TRUE)
}
