checkIfTuneServerIsUp = function(addr, timeout = 1) {
  start.time = Sys.time()
  while (difftime(Sys.time(), start.time, units = "secs") < timeout) {
    test = tryCatch(GET(addr), error = function(e) list(status_code = -1))
    if(test$status_code == 200) {
      return(TRUE)
    }
    Sys.sleep(5)
  }
  return(FALSE)
}
