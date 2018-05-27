context("Supported Learners")

test_that("that all supported learners ", {
  r = startOmlTuneServer()
  expect_true(r)

  learners = c("classif.kknn", "classif.glmnet", "classif.ranger", "classif.rpart", "classif.svm", "classif.xgboost")

  task.id = 3

  for (learner in learners) {
    of = makeOmlBenchFunction(learner, task.id)
    expect_class(of, "smoof_function")
    par.set = getParamSet(of)
    expect_true(hasFiniteBoxConstraints(par.set))
    x = sampleValue(par.set)
    res = of(x)
    # TODO: Assert here that we get auc, accuracy, rmse, scimark and runtime.
    # TODO: Assert that these are numeric.
  }
})
