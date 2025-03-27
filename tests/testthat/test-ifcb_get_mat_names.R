test_that("ifcb_get_mat_names correctly retrieves variable names from a MAT file", {

  mat_file <- system.file("exdata/example.mat", package = "iRfcb")

  # Call the function to get variable names
  variable_names <- ifcb_get_mat_names(mat_file)

  # Expected variable names
  expected_names <- c("TBclass", "TBclass_above_threshold", "TBscores", "class2useTB", "classifierName", "roinum")

  # Check if the retrieved variable names match the expected names
  expect_equal(sort(variable_names), sort(expected_names), info = "Variable names should match expected names")
})

test_that("ifcb_get_mat_names handles non-existent MAT file gracefully", {

  # Define a non-existent file path
  non_existent_file <- "non_existent_file.mat"

  # Call the function to get variable names and expect an error
  expect_error(suppressWarnings(ifcb_get_mat_names(non_existent_file)),
               regexp = NULL,
               info = "Function should handle non-existent file gracefully")
})

test_that("ifcb_get_mat_names correctly retrieves variable names from a MAT file using python", {

  skip_if_no_scipy()

  mat_file <- system.file("exdata/example.mat", package = "iRfcb")

  # Call the function to get variable names
  variable_names <- ifcb_get_mat_names(mat_file, use_python = TRUE)

  # Expected variable names
  expected_names <- c("TBclass", "TBclass_above_threshold", "TBscores", "class2useTB", "classifierName", "roinum")

  # Check if the retrieved variable names match the expected names
  expect_equal(sort(variable_names), sort(expected_names), info = "Variable names should match expected names")
})
