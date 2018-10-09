context("All Learners on all tasks")

r = startOmlTuneServer()
expect_true(r)

task_id = 3
learners = c("classif.kknn", "classif.glmnet", "classif.ranger", "classif.rpart", "classif.svm")# "classif.xgboost")

#availiable_tasks = readRDS("../availiable_tasks.Rds")

for (learner in learners) {
  test_that(learner, {
    of = makeOmlBenchFunction(learner, task_id, include.extras = TRUE)
    expect_class(of, "smoof_function")
    
    # Get random parameter set
    par.set = getParamSet(of)
    expect_true(hasFiniteBoxConstraints(par.set))
    x = sampleValue(par.set)
    
    # Get best approximation from server
    res = of(x)
    expect_number(res)
    
    # Assert that we get auc, accuracy, rmse, scimark and runtime.
    expect_number(attr(res, "extras")[[".lookup.auc"]])
    expect_number(attr(res, "extras")[[".lookup.rmse"]])
    expect_number(attr(res, "extras")[[".lookup.scimark"]])
    expect_number(attr(res, "extras")[[".lookup.runtime"]])
  })
}
