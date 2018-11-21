context("All Learners on all tasks")

task_id = 3
learners = c("classif.kknn", "classif.glmnet", "classif.rpart", "classif.svm", "classif.xgboost", "classif.ranger")

for (learner in learners) {
  test_that(learner, {
    of = make_omlbenchfunction(learner, task_id, include.extras = TRUE)
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

    # with multiple values
    xd = generateRandomDesign(n = 100, par.set)
    res = of(xd)
    expect_numeric(res)
    expect_list(attr(res, "extras"), len = 100, names = "unnamed")
  })
}
