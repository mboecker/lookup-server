library("mlr")
library("ranger")
library("kknn")
library("e1071")
library("xgboost")

# Load the latest parameter definitions from the omlbot github repo.
source("https://raw.githubusercontent.com/ja-thomas/OMLbots/master/R/botMakeLrnPsSets.R")
source("https://raw.githubusercontent.com/ja-thomas/OMLbots/master/R/botSetLearnerParamPairs.R")

# This function generates a named list with an entry for every known algorithm.
# For every algorithm it has upper and lower bounds on each parameter.
parameters = function() {
  raw_data = getMultipleLearners()
  
  # Go through every learner in the data.
  params_per_algo = lapply(raw_data, function(algorithm_data) {
    # For each parameter, extract the lower and upper bounds
    lapply(algorithm_data$param.set$pars, function(parameter_data) {
      list(lower = parameter_data$lower, upper = parameter_data$upper)
    })
  })
  
  # Apply names
  names(params_per_algo) = lapply(raw_data, function(algorithm_data) algorithm_data$learner$id)
  
  params_per_algo
}

# Generate parameter_ranges data.
parameter_ranges = parameters()

# Store them in a file, which will be baked into the docker image.
saveRDS(parameter_ranges, file = "../omlbotlookup/parameter_ranges.Rds")
