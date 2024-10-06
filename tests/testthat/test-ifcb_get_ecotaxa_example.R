test_that("ifcb_get_ecotaxa_example reads the ecotaxa example correctly", {

  # Call the function
  ecotaxa_example <- ifcb_get_ecotaxa_example()

  # Check that the result is a data frame
  expect_true(is.data.frame(ecotaxa_example))

  # Check that the dataframe contains 5 rows
  expect_equal(nrow(ecotaxa_example), 5)
})
