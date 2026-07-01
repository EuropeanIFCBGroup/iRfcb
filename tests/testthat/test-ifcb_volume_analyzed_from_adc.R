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
