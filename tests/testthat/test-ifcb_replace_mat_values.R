library(testthat)
library(reticulate)
library(R.matlab)
library(iRfcb)

# Helper function to create a temporary .mat file with a named classlist object
create_temp_mat_file <- function(file_path, classlist) {
  writeMat(file_path, classlist = classlist) # Ensure 'classlist' is named
}

test_that("ifcb_replace_mat_values correctly updates the .mat classlist files", {
  # Create a temporary directory for the manual_folder
  manual_folder <- tempdir()
  out_folder <- tempdir()

  # Create a test .mat file with a classlist
  test_classlist <- matrix(c(1, 99, 3, 99, 5, 6, 99, 8, 9), ncol = 1, byrow = TRUE)
  test_file <- file.path(manual_folder, "test.mat")
  create_temp_mat_file(test_file, test_classlist)

  # Define the target and new IDs
  target_id <- 99
  new_id <- 1
  column_index <- 0 # Python uses 0-based indexing

  # Create a temporary virtual environment
  venv_dir <- "~/virtualenvs/iRfcb-test"
  reticulate::virtualenv_create(venv_dir, requirements = system.file("python", "requirements.txt", package = "iRfcb"))
  reticulate::use_virtualenv(venv_dir, required = TRUE)

  # Mock the Python function (replace_value_in_classlist)
  mock_replace_value_in_classlist <- function(input_file, output_file, target_value, new_value, column_index) {
    # Read the input .mat file
    mat_contents <- readMat(input_file)
    classlist <- mat_contents$classlist

    # Replace target_value with new_value in the specified column
    mask <- classlist[, column_index + 1] == target_value # Adjust for 1-based indexing in R
    classlist[mask, column_index + 1] <- new_value

    # Write the modified contents to the output .mat file
    writeMat(output_file, classlist = classlist)
  }

  # Use the mock function instead of the actual Python function
  source_python <- function(file) mock_replace_value_in_classlist

  # Run the function
  ifcb_replace_mat_values(manual_folder, out_folder, target_id, new_id, column_index)

  # Verify the output file has the expected changes
  output_file <- file.path(out_folder, "test.mat")
  output_contents <- readMat(output_file)
  output_classlist <- output_contents$classlist

  expected_classlist <- matrix(c(1, 1, 3, 1, 5, 6, 1, 8, 9), ncol = 1, byrow = TRUE)
  expect_equal(output_classlist, expected_classlist)

  # Clean up the temporary virtual environment
  unlink(venv_dir, recursive = TRUE)
  unlink(manual_folder)
})
