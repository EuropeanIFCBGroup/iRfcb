test_that("ifcb_get_ecotaxa_example reads the ecotaxa examples correctly", {

  # Call the function
  ecotaxa_example <- ifcb_get_ecotaxa_example()

  # Check that the result is a data frame
  expect_true(is.data.frame(ecotaxa_example))

  # Check that the dataframe contains 5 rows
  expect_equal(nrow(ecotaxa_example), 3)

  # Call the function
  ecotaxa_example <- ifcb_get_ecotaxa_example(example = "minimal")

  # Check that the result is a data frame
  expect_true(is.data.frame(ecotaxa_example))

  # Check that the dataframe contains 5 rows
  expect_equal(ncol(ecotaxa_example), 2)

  # Call the function
  ecotaxa_example <- ifcb_get_ecotaxa_example(example = "full_unknown")

  # Check that the result is a data frame
  expect_true(is.data.frame(ecotaxa_example))

  # Check that the dataframe contains 5 rows
  expect_equal(ncol(ecotaxa_example), 152)

  # Call the function
  ecotaxa_example <- ifcb_get_ecotaxa_example(example = "full_classified")

  # Check that the result is a data frame
  expect_true(is.data.frame(ecotaxa_example))

  # Check that the dataframe contains 5 rows
  expect_equal(ncol(ecotaxa_example), 86)
})
