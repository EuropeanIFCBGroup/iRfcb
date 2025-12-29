# Directory to extract files
exdir <- file.path(tempdir(), "ifcb_read_hdr_data")

# Extract the files
unzip(test_path("test_data/test_data.zip"), exdir = exdir)

# Define the path to the example HDR file in the package
hdr_file_path <- file.path(exdir, "test_data/data/D20230810T113059_IFCB134.hdr")

test_that("ifcb_read_hdr_data reads HDR data correctly", {
  hdr_folder <- create_temp_hdr_from_example(exdir, hdr_file_path)
  result <- ifcb_read_hdr_data(hdr_folder, verbose = FALSE)

  expect_true(nrow(result) > 0)
  expect_true("sample" %in% names(result))
})

test_that("ifcb_read_hdr_data filters GPS data correctly", {
  hdr_folder <- create_temp_hdr_from_example(exdir, hdr_file_path)
  result <- ifcb_read_hdr_data(hdr_folder, gps_only = TRUE, verbose = FALSE)

  expect_true(nrow(result) > 0)
  expect_true("gpsLatitude" %in% names(result))
  expect_true("gpsLongitude" %in% names(result))
  expect_false("roi_numbers" %in% names(result))
})

test_that("ifcb_read_hdr_data handles verbose output correctly", {
  hdr_folder <- create_temp_hdr_from_example(exdir, hdr_file_path)

  expect_output(ifcb_read_hdr_data(hdr_folder, verbose = TRUE), "Found 1 .hdr files.")
  expect_output(ifcb_read_hdr_data(hdr_folder, verbose = TRUE), "Processing completed.")

  unlink(file.path(hdr_folder, "D20230314T001205_IFCB134.hdr"))
})

test_that("ifcb_read_hdr_data handles no HDR files correctly", {
  hdr_folder <- file.path(exdir, "temp2")
  if (!dir.exists(hdr_folder)) {
    dir.create(hdr_folder)
  }

  expect_error(ifcb_read_hdr_data(hdr_folder, verbose = FALSE),
               "No HDR data found")
})

test_that("ifcb_read_hdr_data handles empty HDR or non-existing data folders correctly", {
  hdr_folder <- file.path(exdir, "temp2")
  if (!dir.exists(hdr_folder)) {
    dir.create(hdr_folder)
  }
  hdr_file <- file.path(hdr_folder, "test_empty.hdr")
  writeLines(character(0), con = hdr_file)

  expect_error(ifcb_read_hdr_data(hdr_folder, verbose = FALSE),
               "No HDR data found")

  expect_error(ifcb_read_hdr_data("not_a_folder", verbose = FALSE),
               "The following hdr_files do not exist")

  unlink(hdr_file)
})

test_that("ifcb_read_hdr_data converts column types correctly", {
  hdr_folder <- create_temp_hdr_from_example(exdir, hdr_file_path)
  result <- ifcb_read_hdr_data(hdr_folder, verbose = FALSE)

  expect_true(is.character(result$GPSFeed))

  unlink(hdr_folder)
})

test_that("ifcb_read_hdr_data handles deprecated arguments correctly", {
  hdr_folder <- create_temp_hdr_from_example(exdir, hdr_file_path)
  lifecycle::expect_deprecated(ifcb_read_hdr_data(hdr_folder = hdr_folder, verbose = FALSE))
})

unlink(exdir)
