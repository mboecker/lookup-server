library(RMySQL)

mysql_username = "root"
mysql_password = ""
mysql_dbname = "openml"
mysql_host = "localhost"

#con <- dbConnect(MySQL(), user=mysql_username, password=mysql_password, dbname=mysql_dbname, host=mysql_host)

json_error <- function(err_msg, more=list()) {
	append(list(error_message = err_msg), more)
}

#* @get /
lookup <- function(...) {
	ls <- as.list(match.call())
	ls[0:3] <- NULL
	list(performance=ls)

	notices = list()

	if(!("alg" %in% names(ls))) {
		error_msg = "Please give the machine learning algorithm you want to use as a parameter (alg=x)."
		return(json_error(error_msg, more=list(missing_args = "alg")))
	}

	algorithm = ls[["alg"]]

	expected_parameters = list("threshold", "k")

	missing_parameters = expected_parameters
	missing_parameters[expected_parameters %in% names(ls)] = NULL

	if(length(missing_parameters) > 0) {
		error_msg = paste0("Please supply adequat parameters for this machine learning algorithm. You are missing: ", paste0(missing_parameters, collapse=", "))
		return(json_error(error_msg, more=list(missing_parameters = simplify2array(missing_parameters))))
	}

	over_parameters = ls
	over_parameters["alg"] = NULL
	over_parameters[names(over_parameters) %in% expected_parameters] = NULL

	if(length(over_parameters) > 0) {
		error_msg = paste0("You supplied too many parameters for this machine learning algorithm: ", paste0(names(over_parameters), collapse=", "))
		notices = append(notices, error_msg)
	}

	response = list(performance = 0.0)

	if(length(notices) > 0) {
		response = append(response, list(notices = notices))
	}

	return(response)
}
