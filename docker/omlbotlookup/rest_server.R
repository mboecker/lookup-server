library(plumber)
r <- plumb("rest_api_handling.R")
r$run(host='0.0.0.0', port=8000)
