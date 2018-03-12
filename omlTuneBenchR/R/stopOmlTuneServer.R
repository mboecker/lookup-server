#' @title Stops a locally running OmlTuneServer.
#' @description If you started your OmlTuneServer locally you can stop and disconnect from it with this function.
#' @return `logical(1)`
#' @export

stopOmlTuneServer = function() {
  out = callShScript("stop-omlbotlookup.sh")
  if (out$success) {
    message(sprintf("The container (%s) was stopped.", out$output))
    disconnectFromOmlTuneServer()
    return(TRUE)
  } else {
    warning(sprintf("Could not stop container. Last output: %s", out$output))
    return(FALSE)
  }
}
