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
  bot.par.sets = extractSubList(raw_data, "param.set", simplify = FALSE)
  
  # we need the defaults of the learners because they are missing in the OpenML Database
  lrn.par.sets = extractSubList(raw_data, c("learner", "par.set"), simplify = FALSE)
  lrn.par.defs = lapply(lrn.par.sets, getDefaults)
  addDefaults = function(par.set, defs) {
    for (n in intersect(names(par.set$pars), names(defs))) {
      par.set$pars[[n]]$default = defs[[n]]
      par.set$pars[[n]]$has.default = TRUE
    }
    return(par.set)
  }
  bot.par.sets = Map(addDefaults, bot.par.sets, lrn.par.defs)
  
  # Manually re-define the default for this "ranger"-parameter, because the new
  # "ignore" option is not implemented in the database but only in mlr.
  bot.par.sets$classif.ranger$pars$respect.unordered.factors$default = "FALSE"
  
  # manually add inverse
  for (n.lrn in names(bot.par.sets)) {
    for (n.par in names(bot.par.sets[[n.lrn]]$pars)) {
      trafo = bot.par.sets[[n.lrn]]$pars[[n.par]]$trafo
      if (!is.null(trafo)) {
        if (all.equal(trafo, function(x) 2^x)) {
          bot.par.sets[[n.lrn]]$pars[[n.par]]$trafo.inverse = function(x) log2(x)
        } else {
          stop("Trafo not cought")
        }
      }
    }
  }
  return(bot.par.sets)
}

# Generate parameter_ranges data.
parameter_ranges = parameters()

# Store them in a file, which will be baked into the docker image.
saveRDS(parameter_ranges, file = "../omlbotlookup/parameter_ranges.Rds")
