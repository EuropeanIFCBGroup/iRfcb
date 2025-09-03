test_that("ifcb_get_runtime correctly extracts runtime and inhibittime from a local header file", {
  # Create a temporary header file with sample content
  temp_dir <- file.path(tempdir(), "ifcb_get_runtime")
  temp_hdr_file <- file.path(temp_dir, "test_header.hdr")

  if (!dir.exists(temp_dir)) {
    dir.create(temp_dir, recursive = TRUE)
  }

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
  temp_dir <- file.path(tempdir(), "ifcb_get_runtime")
  temp_hdr_file <- file.path(temp_dir, "test_header_missing_fields.hdr")

  if (!dir.exists(temp_dir)) {
    dir.create(temp_dir, recursive = TRUE)
  }

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

  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://habon-ifcb.whoi.edu")

  # Attempt to read the header file from the URL, handle potential errors
  hdr_info_db <- tryCatch(
    {
      # Call the function to read the header file from the URL
      ifcb_get_runtime(url)
    },
    error = function(e) {
      # Skip the test with an informative message if the URL fails
      skip(paste("URL not accessible or file not found:", url))
    }
  )

  # Check if the extracted values are correct (example values, adjust as needed)
  expect_equal(hdr_info_db$runtime, 1198.026000, info = "Extracted runtime should be 1198.026")
  expect_equal(hdr_info_db$inhibittime, 0.000000, info = "Extracted inhibittime should be 0")
})
