suppressWarnings({
  library(testthat)
  library(iRfcb)
})

test_that("ifcb_get_runtime correctly extracts runtime and inhibittime from a local header file", {
  # Create a temporary header file with sample content
  temp_dir <- tempdir()
  temp_hdr_file <- file.path(temp_dir, "test_header.hdr")

  hdr_content <- "
    runtime: 123.45
    inhibittime: 67.89
  "

  writeLines(hdr_content, temp_hdr_file)

  # Call the function to read the header file
  hdr_info <- ifcb_get_runtime(temp_hdr_file)

  # Check if the extracted values are correct
  expect_equal(hdr_info$runtime, 123.45, info = "Extracted runtime should be 123.45")
  expect_equal(hdr_info$inhibittime, 67.89, info = "Extracted inhibittime should be 67.89")

  # Clean up the temporary file
  unlink(temp_hdr_file)
})

test_that("ifcb_get_runtime handles missing fields gracefully", {
  # Create a temporary header file with missing fields
  temp_dir <- tempdir()
  temp_hdr_file <- file.path(temp_dir, "test_header_missing_fields.hdr")

  hdr_content <- "
    runtime: 123.45
  "

  writeLines(hdr_content, temp_hdr_file)

  # Call the function to read the header file
  hdr_info <- ifcb_get_runtime(temp_hdr_file)

  # Check if the extracted values are correct and missing fields are handled
  expect_equal(hdr_info$runtime, 123.45, info = "Extracted runtime should be 123.45")
  expect_null(hdr_info$inhibittime, info = "inhibittime should be NULL if not present in the file")
  expect_null(hdr_info$runType, info = "runType should be NULL if not present in the file")

  # Clean up the temporary file
  unlink(temp_hdr_file)
})

test_that("ifcb_get_runtime handles header file from URL", {
  # Example URL
  url <- "https://habon-ifcb.whoi.edu/tangosund/D20161017T161534_IFCB110.hdr"

  # Call the function to read the header file from the URL
  hdr_info <- ifcb_get_runtime(url)

  # Check if the extracted values are correct (example values, adjust as needed)
  expect_equal(hdr_info$runtime, 1198.026000, info = "Extracted runtime should be 123.45")
  expect_equal(hdr_info$inhibittime, 0.000000, info = "Extracted inhibittime should be 67.89")
})
