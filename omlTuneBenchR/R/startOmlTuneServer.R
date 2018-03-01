#' @title Start the OmlTuneServer in a docker locally
#' @description Start the OmlTuneServer in a docker locally and directly connects to it (assumes that docker is correctly installed).
#' @return `logical(1)`
#' @export
startOmlTuneServer = function() {
  # check if server already runs
  if (checkIfTuneServerIsUp(omlTuneBenchR$adress.default)) {
    error("Server is already running!")
  }
  # 
  connectToOmlTuneServer(timeout = 60)
}
