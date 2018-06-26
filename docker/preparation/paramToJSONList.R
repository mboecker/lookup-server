## All copy pasta from jakob-r/mlrHyperopt
## Maybe overkill here!

# converts a Param to a List
# @param param [list]
# @return list
paramToJSONList = function(param) {
  res.list = Filter(function(x) !is.null(x) && length(x) > 0, param) #remove empty list entries
  if (any(names(res.list) %in% getForbiddenParamFields())) {
    stop(sprintf("The Param fields for Param %s are currently not supported: %s", param$id, intersect(names(res.list), getForbiddenParamFields())))
  }
  res.list = res.list[names(res.list) %in% getSupportedParamFields()]
  # deparse all requirements
  if (!is.null(param$requires)) {
    res.list$requires = deparse(param$requires)
  }
  # deparse all expressions
  res.list = lapply(res.list, function(x) {
    if (is.expression(x)) {
      deparse(x)
    } else {
      x
    }
  })
  # handle values for discrete param, currently not supported
  if (param$type == "discrete") {
    res.list$values = checkDiscreteJSON(param$values, param$id)
  }
  # handle trafo
  if (!is.null(param$trafo)) {
    res.list$trafo = deparse(param$trafo)
  }
  res.list
}

# All arguments that are currently not supported for ex- or import.
getForbiddenParamFields = function() {
  c("special.vals")
}

# All arguments that can be stored as JSON, extended,
# @param extended [logical]
#   include arguments that need special treatment
getSupportedParamFields = function(extended = FALSE) {
  res = c("id", "type", "default", "upper", "lower", "values", "tunable", "allow.inf", "len","trafo.inverse")
  if (extended)
    res = c(res, "requires", "trafo")
  res
}

# All supported Values for discrete Parameters
getSupportedDiscreteValues = function() {
  c("character", "integer", "numeric", "data.frame", "matrix", "Date", "POSIXt", "factor", "complex", "raw", "logical")
}

## json helpers

checkDiscreteJSON = function(par.vals, param.id = character()) {
  value.classes = sapply(par.vals, class)
  if (any(!value.classes %in% getSupportedDiscreteValues())) {
    stopf("The values for Param %s contain currently unsupported types: %s", param.id, names(value.classes[value.classes %nin% getSupportedDiscreteValues()]))
  }
  par.vals
}

