# Helpers

# @param script (`character(1)`)
#  Name of the script in inst/docker
callShScript = function(script) {
  script.file = system.file(script, package = "omlTuneBenchR")
  assertFile(script.file)
  out = suppressWarnings(system(script.file, intern = TRUE))
  status = attr(out, "status")
  if (is.null(status)) status = 0
  if (!(status %in% c(0,1))) {
    stop(sprintf("Status code %i not allowed. Output %s", status, out))
  }
  list(
    output = as.vector(out),
    success = status == 0
  )
}

assertConnected = function() {
  if (is.null(omlTuneBenchR$connection)) {
    stop("No connection!")
  } else {
    invisible(TRUE)
  }
}
