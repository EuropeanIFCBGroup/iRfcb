# Directory to extract files
exdir <- file.path(tempdir(), "ifcb_volume_analyzed")

# Extract the files
unzip(test_path("test_data/test_data.zip"),
      files = c("test_data/data/D20220522T003051_IFCB134.adc",
                "test_data/data/D20220522T003051_IFCB134.hdr"),
      exdir = exdir,
      junkpaths = TRUE)

# Define the path to the test HDR file
hdr_file_path <- file.path(exdir, "D20220522T003051_IFCB134.hdr")

test_that("ifcb_volume_analyzed correctly calculates the volume analyzed", {
  # Expected result based on known values in the HDR file
  expected_volume <- 2.9812723

  # Call the function
  calculated_volume <- ifcb_volume_analyzed(hdr_file_path, hdrOnly_flag = TRUE)

  # Check if the calculated volume matches the expected value
  expect_equal(calculated_volume, expected_volume)
})

test_that("ifcb_volume_analyzed handles non-existent file gracefully", {
  # Define a non-existent file path
  non_existent_file <- "non_existent_file.hdr"

  # Call the function and expect an error
  expect_error(suppressWarnings(ifcb_volume_analyzed(non_existent_file, hdrOnly_flag = TRUE)))
})

test_that("ifcb_volume_analyzed works with multiple files", {
  # Define paths to multiple test HDR files
  hdr_file_paths <- c(hdr_file_path, hdr_file_path)  # Using the same file twice for simplicity

  # Expected result based on known values in the HDR files
  expected_volumes <- c(2.9812723, 2.9812723)  # Replace with actual expected values

  # Call the function
  calculated_volumes <- ifcb_volume_analyzed(hdr_file_paths, hdrOnly_flag = TRUE)

  # Check if the calculated volumes match the expected values
  expect_equal(calculated_volumes, expected_volumes)
})

unlink(exdir)
