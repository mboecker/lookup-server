library(plumber)

r <- plumb("rest_api.R")              # <- This line uses the new API.

r$run(host='0.0.0.0', port=8000)
