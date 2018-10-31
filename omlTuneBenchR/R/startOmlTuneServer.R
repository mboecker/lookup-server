#' @title Start the OmlTuneServer in a docker locally
#' @description Start the OmlTuneServer in a docker locally and directly connects to it (assumes that docker is correctly installed).
#' @return `logical(1)`
#' @export
startOmlTuneServer = function() {
  # check if server already runs
  out = callShScript("checkrunning-omlbotlookup.sh")
  if (out$success) {
    if (checkIfTuneServerIsUp(omlTuneBenchR$adress.default, timeout = 600)) {
      message("Server is already running!")
    } else {
      stop("Server is up but not responding!")
    }
  } else {
    # check if a stopped container exists
    out = callShScript("checkstopped-omlbotlookup.sh")
    if (out$success) {
      message(sprintf("An existing container (%s) gets started!", out$output))
      out = callShScript("start-omlbotlookup.sh")
      if (!out$success) {
        stop(sprintf("Could not start existing container! Last output: %s", out$output))
      }
    } else {
      # we have to run new container
      message("Run a new container!")
      out = callShScript("run-omlbotlookup.sh")
      if (!out$success) {
        stop(sprintf("Could not run new container! Last output: %s", out$output))
      }
      
      out = callShScript("import-full-data.sh")
      if (!out$success) {
        stop(sprintf("Could not import data! Last output: %s", out$output))
      }
    }
  }
  # set adress to local (which should be the default)
  connectToOmlTuneServer(omlTuneBenchR$adress.default, timeout = 120)
}
