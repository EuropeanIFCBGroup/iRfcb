test_that("ifcb_correct_annotation updates class IDs correctly", {
  # Skip if Python is not available
  skip_if_no_scipy()
  skip_on_cran()

  # Create a temporary directory for the manual_folder
  manual_folder <- file.path(tempdir(), "manual")
  out_folder <- file.path(tempdir(), "out")
  dir.create(out_folder, showWarnings = FALSE)

  # Extract the files
  unzip(test_path("test_data/test_data.zip"),
        files = "test_data/manual/D20220712T210855_IFCB134.mat",
        exdir = manual_folder,
        junkpaths = TRUE)

  # Create a correction file
  correction_file <- tempfile()
  corrections <- data.frame(
    class_folder = "manual",
    image_filename = c("D20220712T210855_IFCB134_00004.png", "D20220712T210855_IFCB134_00005.png"),
    stringsAsFactors = FALSE
  )
  write.table(corrections, correction_file, row.names = FALSE, col.names = TRUE, quote = FALSE)

  # Expected new class ID
  correct_classid <- 99

  # Mock the Python function (edit_manual_file)
  mock_edit_manual_file <- function(input_file, output_file, row_numbers, new_value) {
    # Read the input .mat file
    mat_contents <- R.matlab::readMat(input_file)
    classlist <- mat_contents$classlist

    # Modify the classlist for each row number
    for (row_number in row_numbers) {
      classlist[row_number, 2] <- new_value
    }

    # Write the modified contents to the output .mat file
    writeMat(output_file, classlist = classlist)
  }

  # Use the mock function instead of the actual Python function
  source_python <- function(file) mock_edit_manual_file

  # Run the function
  ifcb_correct_annotation(manual_folder, out_folder, correction_file, correct_classid)

  # Verify the output file has the expected changes
  output_file <- file.path(out_folder, "D20220712T210855_IFCB134.mat")
  output_contents <- R.matlab::readMat(output_file)
  output_classlist <- output_contents$classlist[,2]

  expected_classlist <- c(rep(1, 3), rep(99, 2), rep(1, 28), 8, rep(1, 44), 8, rep(1, 105))
  expect_equal(output_classlist, expected_classlist)

  # Clean up the temporary virtual environment
  # unlink(venv_dir, recursive = TRUE)
  unlink(out_folder, recursive = TRUE)
  unlink(manual_folder, recursive = TRUE)
  unlink(correction_file)
  unlink(file.path(manual_folder, "D20220712T210855_IFCB134.mat"))
})

test_that("ifcb_correct_annotation works with character vector input", {
  # Skip if Python is not available
  skip_if_no_scipy()
  skip_on_cran()

  # Create a temporary directory for the manual_folder
  manual_folder <- file.path(tempdir(), "manual")
  out_folder <- file.path(tempdir(), "out")
  dir.create(out_folder, showWarnings = FALSE)

  # Extract the files
  unzip(test_path("test_data/test_data.zip"),
        files = "test_data/manual/D20220712T210855_IFCB134.mat",
        exdir = manual_folder,
        junkpaths = TRUE)

  # Provide the corrections directly as a character vector
  correction_vector <- c("D20220712T210855_IFCB134_00004.png", "D20220712T210855_IFCB134_00005.png")

  # Expected new class ID
  correct_classid <- 99

  # Mock the Python function (edit_manual_file)
  mock_edit_manual_file <- function(input_file, output_file, row_numbers, new_value) {
    # Read the input .mat file
    mat_contents <- R.matlab::readMat(input_file)
    classlist <- mat_contents$classlist

    # Modify the classlist for each row number
    for (row_number in row_numbers) {
      classlist[row_number, 2] <- new_value
    }

    # Write the modified contents to the output .mat file
    writeMat(output_file, classlist = classlist)
  }

  # Use the mock function instead of the actual Python function
  source_python <- function(file) mock_edit_manual_file

  # Run the function with the character vector input
  ifcb_correct_annotation(manual_folder, out_folder, correction_vector, correct_classid)

  # Verify the output file has the expected changes
  output_file <- file.path(out_folder, "D20220712T210855_IFCB134.mat")
  output_contents <- R.matlab::readMat(output_file)
  output_classlist <- output_contents$classlist[,2]

  expected_classlist <- c(rep(1, 3), rep(99, 2), rep(1, 28), 8, rep(1, 44), 8, rep(1, 105))
  expect_equal(output_classlist, expected_classlist)

  # Clean up
  unlink(out_folder, recursive = TRUE)
  unlink(manual_folder, recursive = TRUE)
})

test_that("ifcb_correct_annotation handles deprecated arguments correctly", {
  # Skip if Python is not available
  skip_if_no_scipy()
  skip_on_cran()

  # Create a temporary directory for the manual_folder
  manual_folder <- file.path(tempdir(), "manual")
  out_folder <- file.path(tempdir(), "out")
  dir.create(out_folder, showWarnings = FALSE)

  # Extract the files
  unzip(test_path("test_data/test_data.zip"),
        files = "test_data/manual/D20220712T210855_IFCB134.mat",
        exdir = manual_folder,
        junkpaths = TRUE)

  # Create a correction file
  correction_file <- tempfile()
  corrections <- data.frame(
    class_folder = "manual",
    image_filename = c("D20220712T210855_IFCB134_00004.png", "D20220712T210855_IFCB134_00005.png"),
    stringsAsFactors = FALSE
  )
  write.table(corrections, correction_file, row.names = FALSE, col.names = TRUE, quote = FALSE)

  # Expected new class ID
  correct_classid <- 99

  # Mock the Python function (edit_manual_file)
  mock_edit_manual_file <- function(input_file, output_file, row_numbers, new_value) {
    # Read the input .mat file
    mat_contents <- R.matlab::readMat(input_file)
    classlist <- mat_contents$classlist

    # Modify the classlist for each row number
    for (row_number in row_numbers) {
      classlist[row_number, 2] <- new_value
    }

    # Write the modified contents to the output .mat file
    writeMat(output_file, classlist = classlist)
  }

  # Use the mock function instead of the actual Python function
  source_python <- function(file) mock_edit_manual_file

  # Run the function
  lifecycle::expect_deprecated(ifcb_correct_annotation(manual_folder,
                                                       out_folder,
                                                       correction_file = correction_file,
                                                       correct_classid = correct_classid))

  # Clean up the temporary virtual environment
  # unlink(venv_dir, recursive = TRUE)
  unlink(out_folder, recursive = TRUE)
  unlink(manual_folder, recursive = TRUE)
  unlink(correction_file)
  unlink(file.path(manual_folder, "D20220712T210855_IFCB134.mat"))
})

test_that("ifcb_correct_annotation handles errors gracefully", {
  # Skip if Python is not available
  skip_if_no_scipy()
  skip_on_cran()

  # Create a temporary directory for the manual_folder
  manual_folder <- file.path(tempdir(), "manual")
  out_folder <- file.path(tempdir(), "out")
  dir.create(out_folder, showWarnings = FALSE)

  # Extract the files
  unzip(test_path("test_data/test_data.zip"),
        files = "test_data/manual/D20220712T210855_IFCB134.mat",
        exdir = manual_folder,
        junkpaths = TRUE)

  # Expected new class ID
  correct_classid <- 99

  # Mock the Python function (edit_manual_file)
  mock_edit_manual_file <- function(input_file, output_file, row_numbers, new_value) {
    # Read the input .mat file
    mat_contents <- R.matlab::readMat(input_file)
    classlist <- mat_contents$classlist

    # Modify the classlist for each row number
    for (row_number in row_numbers) {
      classlist[row_number, 2] <- new_value
    }

    # Write the modified contents to the output .mat file
    writeMat(output_file, classlist = classlist)
  }

  # Use the mock function instead of the actual Python function
  source_python <- function(file) mock_edit_manual_file

  # Run the function and expect error
  expect_error(ifcb_correct_annotation(manual_folder,
                                       out_folder,
                                       correction = 999,
                                       correct_classid = correct_classid),
               "Invalid input: `correction` should be a file path or a character vector")

  # Run the function and expect error
  expect_error(ifcb_correct_annotation(manual_folder,
                                       out_folder,
                                       correction = NULL,
                                       correct_classid = correct_classid),
               "argument `correction` is missing, with no default")

  # Clean up the temporary virtual environment
  unlink(out_folder, recursive = TRUE)
  unlink(manual_folder, recursive = TRUE)
  unlink(file.path(manual_folder, "D20220712T210855_IFCB134.mat"))
})
