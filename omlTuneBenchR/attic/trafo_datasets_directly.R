learner_id = "classif.svm"
task_id = 3
par_set = parameter_ranges[[learner_id]]
task_metadata = get_task_metadata(task_id)
table = get_runs(learner_id, task_id)
head(table)
par_names = getParamIds(par_set, TRUE, TRUE)

# apply reverse transformation
for (par_name in par_names) {
  par_trafo_inv = par_set$pars[[par_name]]$trafo.inverse
  if (!is.null(par_trafo_inv)) {
    table[[par_name]] = par_trafo_inv(table[[par_name]])
  }
}