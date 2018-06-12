context("All Learners on task 3")

r = startOmlTuneServer()
expect_true(r)

task.id = 3
learners = c("classif.kknn", "classif.glmnet", "classif.ranger", "classif.rpart")# FIXME: , "classif.svm", "classif.xgboost")

for (learner in learners) {
  test_that(learner, {
    of = makeOmlBenchFunction(learner, task.id)
    expect_class(of, "smoof_function")
    
    # Get random parameter set
    par.set = getParamSet(of)
    expect_true(hasFiniteBoxConstraints(par.set))
    x = sampleValue(par.set)
    
    # Get best approximation from server
    res = of(x)
    expect_number(res)
    
    # Assert that we get auc, accuracy, rmse, scimark and runtime.
    expect_number(attr(res, "extras")[[1]][["auc"]])
    expect_number(attr(res, "extras")[[1]][["rmse"]])
    expect_number(attr(res, "extras")[[1]][["scimark"]])
    expect_number(attr(res, "extras")[[1]][["runtime"]])
  })
}
