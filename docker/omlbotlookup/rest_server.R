library(plumber)
r <- plumb("/mysqldata/rest_api_handling.R")
r$run(host='0.0.0.0', port=8000)
