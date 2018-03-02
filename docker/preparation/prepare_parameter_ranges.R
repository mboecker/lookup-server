library("mlr")
library("ranger")
library("kknn")
library("e1071")
library("xgboost")
library("checkmate")
library("BBmisc")

# Load the latest parameter definitions from the omlbot github repo.
source("https://raw.githubusercontent.com/ja-thomas/OMLbots/master/R/botMakeLrnPsSets.R")
source("https://raw.githubusercontent.com/ja-thomas/OMLbots/master/R/botSetLearnerParamPairs.R")

# This function generates a named list with an entry for every known algorithm.
# For every algorithm it has upper and lower bounds on each parameter.
parameters = function() {
  raw_data = getMultipleLearners()
  names(raw_data) = extractSubList(raw_data, element = c("learner", "id"))
  raw_data = extractSubList(raw_data, "param.set", simplify = FALSE)
  return(raw_data)
}

# Generate parameter_ranges data.
parameter_ranges = parameters()

# Store them in a file, which will be baked into the docker image.
saveRDS(parameter_ranges, file = "../omlbotlookup/parameter_ranges.Rds")
