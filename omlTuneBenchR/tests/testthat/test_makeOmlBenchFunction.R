context("makeOmlBenchFunction")

test_that("simple: kknn", {
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
  
  expect_numeric(res)
})


test_that("complex: randomForest", {
  r = startOmlTuneServer()
  expect_true(r)

  lrn.str = "classif.ranger"
  task.id = 3
  of = makeOmlBenchFunction(lrn.str, task.id, include.extras = TRUE)
  expect_class(of, "smoof_function")
  par.set = getParamSet(of)
  expect_true(hasFiniteBoxConstraints(par.set))

  x = sampleValue(par.set)
  res = of(x)
  expect_numeric(res)
  expect_list(attr(res, "extras"), names = "named")

  ## Now with multiple values
  xs = generateRandomDesign(20, par.set)
  res = of(xs)
  expect_numeric(res)
  expect_list(attr(res, "extras"), len = 20, names = "unnamed")

})

test_that("on specific value with trafos works", {
  # this is not necessary elegant
  # but if this fails we see that something is broken majorily
  of = makeOmlBenchFunction("classif.svm", 3, include.extras = TRUE)
  x = list(kernel = "radial", cost = 4.643833, gamma = -6.928392, degree = NA_integer_)
  res = of(x)
  expect_equal(attr(res,"extras")$.lookup.rid, 2127568)
  expect_equal(as.numeric(res), 0.9631)
})