context("makeOmlBenchFunction")

test_that("omlBenchFunctions work", {
  r = startOmlTuneServer()
  expect_true(r)

  lrn.str = "classif.kknn"
  task.id = 3
  of = makeOmlBenchFunction(lrn.str, task.id)
  expect_class(of, "smoof_function")
  par.set = getParamSet(of)
  expect_true(hasFiniteBoxConstraints(par.set))

  x = sampleValue(par.set)
  res = of(x)
  
  # TODO: Assert here that we get auc, accuracy, rmse, scimark and runtime.
  # TODO: Assert that these are numeric.
})
