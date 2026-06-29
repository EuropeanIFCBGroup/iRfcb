test_that("ifcb_correct_annotation updates class IDs correctly", {

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

  # Run the function and expect error
  expect_error(ifcb_correct_annotation(manual_folder,
                                       out_folder,
                                       correction = 999,
                                       correct_classid = correct_classid),
               "should be a file path or a character vector")

  # Run the function and expect error
  expect_error(ifcb_correct_annotation(manual_folder,
                                       out_folder,
                                       correction = NULL,
                                       correct_classid = correct_classid),
               "is missing, with no default")

  # Clean up the temporary virtual environment
  unlink(out_folder, recursive = TRUE)
  unlink(manual_folder, recursive = TRUE)
  unlink(file.path(manual_folder, "D20220712T210855_IFCB134.mat"))
})

test_that("ifcb_correct_annotation errors clearly on an out-of-range ROI", {

  # Create a temporary directory for the manual_folder
  manual_folder <- file.path(tempdir(), "manual_oor")
  out_folder <- file.path(tempdir(), "out_oor")
  dir.create(out_folder, showWarnings = FALSE)

  # Extract a manual file (its classlist has far fewer than 99999 ROIs)
  unzip(test_path("test_data/test_data.zip"),
        files = "test_data/manual/D20220712T210855_IFCB134.mat",
        exdir = manual_folder,
        junkpaths = TRUE)

  # A correction referencing an ROI beyond the end of the classlist should abort
  # with a message naming the file and the offending ROI, rather than dying with
  # an opaque "subscript out of bounds".
  expect_error(
    ifcb_correct_annotation(manual_folder, out_folder,
                            correction = "D20220712T210855_IFCB134_99999.png",
                            correct_classid = 99),
    "ROI"
  )

  unlink(out_folder, recursive = TRUE)
  unlink(manual_folder, recursive = TRUE)
})
