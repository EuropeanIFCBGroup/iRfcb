test_that("ifcb_replace_mat_values correctly updates the .mat classlist files", {
  # Skip if Python is not available
  skip_if_no_scipy()
  skip_on_cran()

  # Create a temporary directory for the manual_folder
  manual_folder <- file.path(tempdir(), "manual")
  out_folder <- file.path(tempdir(), "out")

  # Create a test .mat file with a classlist
  test_classlist <- matrix(c(1, 99, 3, 99, 5, 6, 99, 8, 9), ncol = 1, byrow = TRUE)
  test_file <- file.path(manual_folder, "test.mat")
  create_temp_mat_file(test_file, test_classlist)

  # Define the target and new IDs
  target_id <- 99
  new_id <- 1
  column_index <- 0 # Python uses 0-based indexing

  # Use the mock function instead of the actual Python function
  source_python <- function(file) mock_replace_value_in_classlist

  # Run the function
  ifcb_replace_mat_values(manual_folder, out_folder, target_id, new_id, column_index)

  # Verify the output file has the expected changes
  output_file <- file.path(out_folder, "test.mat")
  output_contents <- R.matlab::readMat(output_file)
  output_classlist <- output_contents$classlist

  expected_classlist <- matrix(c(1, 1, 3, 1, 5, 6, 1, 8, 9), ncol = 1, byrow = TRUE)
  expect_equal(output_classlist, expected_classlist)

  # Clean up the temporary virtual environment
  unlink(manual_folder)
})

test_that("ifcb_replace_mat_values handles missing manual folder gracefully", {
  # Skip if Python is not available
  skip_if_no_scipy()

  manual_folder <- file.path(tempdir(), "nonexistent")
  out_folder <- file.path(tempdir(), "out")

  expect_error(ifcb_replace_mat_values(manual_folder, out_folder, 99, 1),
               paste("The manual folder does not exist:"))

  unlink(manual_folder, recursive = TRUE)
})

test_that("ifcb_replace_mat_values handles missing files in manual folder gracefully", {
  # Skip if Python is not available
  skip_if_no_scipy()

  manual_folder <- file.path(tempdir(), "manual")
  out_folder <- file.path(tempdir(), "out")

  manual_folder <- file.path(tempdir(), "empty_dir")

  if(!dir.exists(manual_folder)) {
    dir.create(manual_folder, recursive = TRUE)
  }

  if(!dir.exists(out_folder)) {
    dir.create(out_folder, recursive = TRUE)
  }

  expect_error(ifcb_replace_mat_values(manual_folder, out_folder, 99, 1, 0),
               paste("No files found in the manual folder:"))

  unlink(manual_folder, recursive = TRUE)
})

test_that("ifcb_replace_mat_values creates output directory if it does not exist", {
  # Skip if Python is not available
  skip_if_no_scipy()

  manual_folder <- file.path(tempdir(), "manual")
  out_folder <- file.path(tempdir(), "new_output")

  # Create a test .mat file with a classlist
  test_classlist <- matrix(c(1, 99, 3, 99, 5, 6, 99, 8, 9), ncol = 1, byrow = TRUE)
  column_index <- 0 # Python uses 0-based indexing
  test_file <- file.path(manual_folder, "test.mat")
  create_temp_mat_file(test_file, test_classlist)

  # Run the function
  ifcb_replace_mat_values(manual_folder, out_folder, 99, 1, column_index)

  # Verify the output directory was created and contains the expected file
  expect_true(dir.exists(out_folder))
  output_file <- file.path(out_folder, "test.mat")
  expect_true(file.exists(output_file))

  # Clean up temporary directories
  unlink(manual_folder)
  unlink(out_folder, recursive = TRUE)
})

test_that("ifcb_replace_mat_values handles different column indices correctly", {
  # Skip if Python is not available
  skip_if_no_scipy()

  manual_folder <- file.path(tempdir(), "manual")
  out_folder <- file.path(tempdir(), "out")

  # Create a test .mat file with a classlist having multiple columns
  test_classlist <- matrix(c(1, 2, 99, 3, 4, 99, 5, 6, 99), ncol = 3, byrow = TRUE)
  test_file <- file.path(manual_folder, "test.mat")
  create_temp_mat_file(test_file, test_classlist)

  # Define the target and new IDs
  target_id <- 99
  new_id <- 1
  column_index <- 2 # Update the third column

  # Use the mock function instead of the actual Python function
  source_python <- function(file) mock_replace_value_in_classlist

  # Run the function
  ifcb_replace_mat_values(manual_folder, out_folder, target_id, new_id, column_index)

  # Verify the output file has the expected changes
  output_file <- file.path(out_folder, "test.mat")
  output_contents <- R.matlab::readMat(output_file)
  output_classlist <- output_contents$classlist

  expected_classlist <- matrix(c(1, 2, 1, 3, 4, 1, 5, 6, 1), ncol = 3, byrow = TRUE)
  expect_equal(output_classlist, expected_classlist)

  # Clean up temporary directories
  unlink(manual_folder)
  unlink(out_folder, recursive = TRUE)
})
