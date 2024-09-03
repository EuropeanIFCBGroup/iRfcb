test_that("ifcb_correct_annotation updates class IDs correctly", {
  # # Skip the test if Python environment is not available
  # skip_if_not(py_available(initialize = TRUE), "Python environment is not available")

  # Create a temporary directory for the manual_folder
  manual_folder <- tempdir()
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

  # Create a temporary virtual environment
  venv_dir <- "~/.virtualenvs/iRfcb"

  # Install a temporary virtual environment
  if (reticulate::virtualenv_exists(venv_dir)) {
    reticulate::use_virtualenv(venv_dir, required = TRUE)
  } else {
    reticulate::virtualenv_create(venv_dir, requirements = system.file("python", "requirements.txt", package = "iRfcb"))
    reticulate::use_virtualenv(venv_dir, required = TRUE)
  }

  # Mock the Python function (edit_manual_file)
  mock_edit_manual_file <- function(input_file, output_file, row_numbers, new_value) {
    # Read the input .mat file
    mat_contents <- readMat(input_file)
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
  output_contents <- readMat(output_file)
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
