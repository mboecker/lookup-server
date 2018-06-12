#' @title Lists all available Task Ids
#' @description Queries the API to return all Task Ids that can be used.

#' @return [`numeric`]
listTaskIds = function() {
  httr.res = httr::GET(paste(omlTuneBenchR$connection, "tasks"), httr::accept_json())
  res = httr::content(httr.res)
}
