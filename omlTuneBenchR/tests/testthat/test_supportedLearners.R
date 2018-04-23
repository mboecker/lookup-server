test_that("that all supported learners ", {
  r = startOmlTuneServer()
  expect_true(r)
  
  learners = c("classif.kknn", "classif.glmnet", "classif.ranger")
  
  task.id = 3
  
  for (learner in learners) {
    of = makeOmlBenchFunction(learner, task.id)
    expect_class(of, "smoof_function")
    par.set = getParamSet(of)
    expect_true(hasFiniteBoxConstraints(par.set))
    x = sampleValue(par.set)
    res = of(x)
    expect_number(res)  
  }
  
})
