suppressWarnings(library(testthat))

# Directory to extract files
exdir <- tempdir()

# Extract the files
unzip(test_path("test_data/test_data.zip"),
      files = "test_data/data/D20220522T003051_IFCB134.adc",
      exdir = exdir,
      junkpaths = TRUE)

# Define the path to the test ADC file
adc_file_path <- file.path(exdir, "D20220522T003051_IFCB134.adc")

test_that("ifcb_volume_analyzed_from_adc correctly calculates the volume analyzed", {
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
})

test_that("ifcb_volume_analyzed_from_adc handles non-existent file gracefully", {
  # Define a non-existent file path
  non_existent_file <- "non_existent_file.adc"

  # Call the function and expect an error
  expect_error(suppressWarnings(ifcb_volume_analyzed_from_adc(non_existent_file)))
})

# test_that("ifcb_volume_analyzed_from_adc works with multiple files", {
#   # Define paths to multiple test ADC files
#   adc_file_paths <- c(adc_file_path, adc_file_path)  # Using the same file twice for simplicity
#
#   # Expected results based on known values in the ADC files
#   expected_ml_analyzed <- c(2.9812723, 2.9812723)
#   expected_runtime <- c(715.6575, 715.6575)
#   expected_inhibittime <- c(0.15215061, 0.15215061)
#
#   # Call the function
#   adc_info <- ifcb_volume_analyzed_from_adc(adc_file_paths)
#
#   # Check if the calculated ml_analyzed matches the expected values
#   expect_equal(adc_info$ml_analyzed, expected_ml_analyzed)
#
#   # Check if the extracted runtime matches the expected values
#   expect_equal(adc_info$runtime, expected_runtime)
#
#   # Check if the extracted inhibittime matches the expected values
#   expect_equal(adc_info$inhibittime, expected_inhibittime)
# })

unlink(exdir)
