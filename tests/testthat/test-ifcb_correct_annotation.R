test_that("ifcb_correct_annotation updates class IDs correctly", {
  skip_if_not_installed("R.matlab") # used as an independent cross-check below

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
  skip_if_not_installed("R.matlab") # used as an independent cross-check below

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

test_that("a correction larger than the stored integer class widens the classlist", {
  manual_folder <- file.path(tempdir(), "manual_uint8_corr")
  out_folder <- file.path(tempdir(), "out_uint8_corr")
  on.exit(unlink(c(manual_folder, out_folder), recursive = TRUE), add = TRUE)
  dir.create(manual_folder, showWarnings = FALSE, recursive = TRUE)
  dir.create(out_folder, showWarnings = FALSE, recursive = TRUE)

  sample_name <- "D20220101T000000_IFCB001"
  write_mat_v5(file.path(manual_folder, paste0(sample_name, ".mat")), list(
    classlist = mat_var_numeric(cbind(1:3, c(1, 1, 1), c(1, 1, 1)), 9L) # mxUINT8
  ))

  correction_file <- tempfile(fileext = ".txt")
  on.exit(unlink(correction_file), add = TRUE)
  corrections <- data.frame(
    class_folder = "manual",
    image_filename = paste0(sample_name, "_00002.png")
  )
  write.table(corrections, correction_file, row.names = FALSE, col.names = TRUE, quote = FALSE)

  # 300 does not fit uint8; it used to be written back as 44.
  ifcb_correct_annotation(manual_folder, out_folder, correction_file, correct_classid = 300)

  back <- read_mat_v5(file.path(out_folder, paste0(sample_name, ".mat")))
  expect_equal(back$classlist$data[, 2], c(1, 300, 1))
  expect_equal(back$classlist$class_code, 6L) # widened to mxDOUBLE
})

test_that("a classlist with fewer than 2 columns aborts with a named message", {
  manual_folder <- file.path(tempdir(), "manual_1col")
  out_folder <- file.path(tempdir(), "out_1col")
  on.exit(unlink(c(manual_folder, out_folder), recursive = TRUE), add = TRUE)
  dir.create(manual_folder, showWarnings = FALSE, recursive = TRUE)

  sample_name <- "D20220101T000000_IFCB001"
  write_mat_v5(file.path(manual_folder, paste0(sample_name, ".mat")),
               list(classlist = mat_var_double(matrix(1:3, ncol = 1))))

  correction_file <- tempfile(fileext = ".txt")
  on.exit(unlink(correction_file), add = TRUE)
  write.table(data.frame(class_folder = "manual",
                         image_filename = paste0(sample_name, "_00002.png")),
              correction_file, row.names = FALSE, col.names = TRUE, quote = FALSE)

  # Used to die with the bare "subscript out of bounds" the 0.10.0 validation
  # was added to replace.
  expect_error(
    ifcb_correct_annotation(manual_folder, out_folder, correction_file, correct_classid = 5),
    "at least 2 columns"
  )
})
