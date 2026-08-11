test_that("ifcb_volume_analyzed_from_adc correctly calculates the volume analyzed", {
  # Directory to extract files
  exdir <- file.path(tempdir(), "ifcb_volume_analyzed_from_adc")

  # Extract the files
  unzip(test_path("test_data/test_data.zip"),
        files = "test_data/data/D20220522T003051_IFCB134.adc",
        exdir = exdir,
        junkpaths = TRUE)

  # Define the path to the test ADC file
  adc_file_path <- file.path(exdir, "D20220522T003051_IFCB134.adc")
  # Expected results based on known values in the ADC file
  expected_ml_analyzed <- 2.9812723
  expected_runtime <- 715.6575
  expected_inhibittime <- 0.1521506

  # Call the function
  adc_info <- ifcb_volume_analyzed_from_adc(adc_file_path)

  # Check if the calculated ml_analyzed matches the expected value
  expect_equal(adc_info$ml_analyzed, expected_ml_analyzed)

  # Check if the extracted runtime matches the expected value
  expect_equal(adc_info$runtime, expected_runtime)

  # Check if the extracted inhibittime matches the expected value
  expect_equal(adc_info$inhibittime, expected_inhibittime, tolerance = 1e-7)

  unlink(exdir)
})

test_that("ifcb_volume_analyzed_from_adc handles non-existent file gracefully", {
  # Define a non-existent file path
  non_existent_file <- "non_existent_file.adc"

  # Call the function and expect an error
  expect_error(ifcb_volume_analyzed_from_adc(non_existent_file),
               "ADC file not found")
})

test_that("ifcb_volume_analyzed_from_adc processes multiple files", {
  # Directory to extract files
  exdir <- file.path(tempdir(), "ifcb_volume_analyzed_from_adc_multi")

  # Extract the files
  unzip(test_path("test_data/test_data.zip"),
        files = "test_data/data/D20220522T003051_IFCB134.adc",
        exdir = exdir,
        junkpaths = TRUE)

  adc_file_path <- file.path(exdir, "D20220522T003051_IFCB134.adc")

  # Passing a vector of paths should return one result per file (previously this
  # errored at the existence check with "the condition has length > 1")
  adc_info <- ifcb_volume_analyzed_from_adc(c(adc_file_path, adc_file_path))

  expect_length(adc_info$ml_analyzed, 2)
  expect_equal(adc_info$ml_analyzed, rep(2.9812723, 2))

  unlink(exdir)
})

test_that("ifcb_volume_analyzed_from_adc reports all missing files in a vector", {
  # A vector containing a missing path should error and name the missing file
  expect_error(
    ifcb_volume_analyzed_from_adc(c("missing_one.adc", "missing_two.adc")),
    "ADC file"
  )
})

# Write a minimal 24-column ADC file with the given timestamp (V2), run time
# (V23) and inhibit time (V24) clocks.
write_test_adc <- function(path, adc_time, run_time, inhibit_time) {
  n <- length(adc_time)
  m <- matrix(0, nrow = n, ncol = 24)
  m[, 2] <- adc_time
  m[, 23] <- run_time
  m[, 24] <- inhibit_time
  write.table(m, path, sep = ",", row.names = FALSE, col.names = FALSE)
}

test_that("the startup-offset branch runs and applies the statistical mode", {
  dir <- file.path(tempdir(), "adc_offset")
  dir.create(dir, showWarnings = FALSE)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  adc <- file.path(dir, "D20220101T000000_IFCB001.adc")

  # Run/inhibit clocks lead the ADC timestamp by 100 s (> 10 s), the exact
  # instrument case this correction exists for. mode() used to resolve to
  # base::mode() here, so this branch always aborted with
  # "non-numeric argument to binary operator".
  write_test_adc(adc,
                 adc_time     = c(0.5, 1.0, 1.5, 2.0, 2.5),
                 run_time     = c(100.5, 101.0, 101.5, 102.0, 102.5),
                 inhibit_time = c(90.02, 90.04, 90.06, 90.08, 90.10))

  res <- ifcb_volume_analyzed_from_adc(adc)

  # runtime = 102.5 - offset 100; inhibittime = 90.10 - (90.04 + 2 * 0.02).
  expect_equal(res$runtime, 2.5)
  expect_equal(res$inhibittime, 0.02)
  expect_equal(res$ml_analyzed, 0.25 * (2.5 - 0.02) / 60)
})

test_that("corrupt inhibit-time rows are repaired with the mode, as in MATLAB", {
  dir <- file.path(tempdir(), "adc_badrows")
  dir.create(dir, showWarnings = FALSE)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  adc <- file.path(dir, "D20220101T000000_IFCB001.adc")

  # Rows 4 and 5 carry corrupted inhibit values (a spurious jump and its
  # reversal). The reference takes the last good row plus one mode increment
  # per bad row; the port used to take the corrupted last row as-is.
  write_test_adc(adc,
                 adc_time     = c(0.5, 1.0, 1.5, 2.0, 2.5),
                 run_time     = c(0.5, 1.0, 1.5, 2.0, 2.5),
                 inhibit_time = c(0.02, 0.04, 0.06, 9999, 0.10))

  res <- ifcb_volume_analyzed_from_adc(adc)

  # Last good row (0.06) + 2 bad rows * mode increment (0.02).
  expect_equal(res$inhibittime, 0.10)
  expect_equal(res$runtime, 2.5)
})

test_that("an ADC without run/inhibit columns yields NA, not zero", {
  dir <- file.path(tempdir(), "adc_short")
  dir.create(dir, showWarnings = FALSE)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  short_adc <- file.path(dir, "D20220101T000000_IFCB001.adc")
  writeLines(c("1,2,3", "4,5,6"), short_adc)

  # A volume of 0 would read as "the instrument analyzed no water"; an
  # underivable volume must be NA (the reference returns NaN).
  expect_warning(res <- ifcb_volume_analyzed_from_adc(short_adc), "run/inhibit")
  expect_true(is.na(res$ml_analyzed))
  expect_true(is.na(res$runtime))
  expect_true(is.na(res$inhibittime))
})

test_that("ifcb_volume_analyzed keeps header values when the ADC estimate is NA", {
  dir <- file.path(tempdir(), "adc_na_hdr")
  dir.create(dir, showWarnings = FALSE)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)

  writeLines(c("runtime: 120", "inhibittime: 12"),
             file.path(dir, "D20220101T000000_IFCB001.hdr"))
  writeLines(c("1,2,3", "4,5,6"),
             file.path(dir, "D20220101T000000_IFCB001.adc"))

  # MATLAB's NaN comparisons are false, so the header values survive; the R
  # port used to compare against a spurious 0 instead.
  ml <- suppressWarnings(
    ifcb_volume_analyzed(file.path(dir, "D20220101T000000_IFCB001.hdr"))
  )
  expect_equal(ml, 0.25 * (120 - 12) / 60)
})
