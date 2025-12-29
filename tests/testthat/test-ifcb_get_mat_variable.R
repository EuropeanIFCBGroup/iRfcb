test_that("ifcb_get_mat_variable correctly retrieves a specified variable from a MAT file", {

  # Define the path to the example .mat file included in the iRfcb package
  mat_file <- system.file("exdata/example.mat", package = "iRfcb")

  # Ensure the example .mat file exists
  expect_true(file.exists(mat_file), info = "Example .mat file should exist")

  # Call the function to get the 'class2use' variable
  classes <- ifcb_get_mat_variable(mat_file, "classifierName")

  # Call the function to get the 'class2use' variable using Python
  classes_py <- ifcb_get_mat_variable(mat_file, "classifierName", use_python = TRUE)

  # Expect that the .mat data from R and Python are identical
  expect_identical(classes, classes_py)

  # Check if the retrieved classes are as expected (assuming you know the expected classes)
  expected_classes <- "Z:\\data\\manual\\Skagerrak-Kattegat\\summary\\results_21May202421May2024"
  expect_equal(classes[1], expected_classes, info = "Retrieved classes should match expected values")
})

test_that("ifcb_get_mat_variable handles missing variable gracefully", {

  # Define the path to the example .mat file included in the iRfcb package
  mat_file <- system.file("exdata/example.mat", package = "iRfcb")

  # Ensure the example .mat file exists
  expect_true(file.exists(mat_file), info = "Example .mat file should exist")

  # Call the function with a non-existent variable name and expect an error
  expect_error(ifcb_get_mat_variable(mat_file, "non_existent_variable"),
               regexp = "Variable name not found in MAT file",
               info = "Function should handle non-existent variable name gracefully")
})

test_that("ifcb_get_mat_variable handles empty MAT file gracefully", {

  # Create a temporary directory and file for the test
  temp_dir <- file.path(tempdir(), "ifcb_get_mat_variable")
  empty_mat_file <- file.path(temp_dir, "empty_test_file.mat")

  # Create an empty .mat file
  R.matlab::writeMat(empty_mat_file, x = list())

  # Ensure the empty .mat file is created
  expect_true(file.exists(empty_mat_file), info = "Empty .mat file should be created")

  # Call the function and expect an error due to missing variable
  expect_error(ifcb_get_mat_variable(empty_mat_file, "classifierName"),
               regexp = "Variable name not found in MAT file",
               info = "Function should handle empty MAT file gracefully")

  # Clean up the temporary file
  unlink(empty_mat_file)
})

test_that("ifcb_get_mat_variable handles non-existing MAT file paths gracefully", {
  # Call the function and expect an error due to missing variable
  expect_error(ifcb_get_mat_variable("not_a_file"),
               regexp = "MAT file does not exist")
})
