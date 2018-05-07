library(plumber)
r <- plumb("rest_api.R")
r$run(host='0.0.0.0', port=8746)
