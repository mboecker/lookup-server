library("checkmate")

is_number = function(x) {
  testInt(suppressWarnings(as.numeric(x)))
}

json_error <- function(err_msg, more=list()) {
  append(list(error_message = err_msg), more)
}
