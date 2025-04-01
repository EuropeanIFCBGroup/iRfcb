# Extract test data and define paths
zip_path <- test_path("test_data/test_data.zip")
temp_dir <- file.path(tempdir(), "ifcb_summarize_png_counts")
unzip(zip_path, exdir = temp_dir)

# Define paths to the unzipped folders
png_folder <- file.path(temp_dir, "test_data/png")
hdr_folder <- file.path(temp_dir, "test_data/data")

# Ensure the temporary directories are cleaned up after tests
on.exit({
  unlink(temp_dir, recursive = TRUE)
}, add = TRUE)

test_that("ifcb_summarize_png_counts works correctly with sample data", {
  # Run the function with summarization level "sample"
  summary_sample <- ifcb_summarize_png_counts(png_folder, hdr_folder, sum_level = "sample", verbose = TRUE)

  # Check that the returned object is a data frame
  expect_s3_class(summary_sample, "data.frame")

  # Check that the data frame contains the expected columns
  expected_columns_sample <- c("sample", "ifcb_number", "class_name", "n_images", "gpsLatitude", "gpsLongitude", "timestamp", "date", "year", "month", "day", "time", "roi_numbers")
  expect_true(all(expected_columns_sample %in% names(summary_sample)))

  # Check that the data frame has non-zero rows
  expect_gt(nrow(summary_sample), 0)

  # Check some specific values (replace with expected values based on your test data)
  # Example: Check if specific sample and class_name exist in the output
  expect_true("D20230810T113059_IFCB134" %in% summary_sample$sample)
  expect_true("Cryptomonadales" %in% summary_sample$class_name)

  # Example: Check if n_images are calculated correctly
  expected_n_images <- 1  # Example value
  expect_equal(summary_sample$n_images[1], expected_n_images)

  # Run the function with summarization level "class"
  summary_class <- ifcb_summarize_png_counts(png_folder, hdr_folder, sum_level = "class", verbose = TRUE)

  # Check that the returned object is a data frame
  expect_s3_class(summary_sample, "data.frame")

  # Check that the data frame contains the expected columns
  expected_columns_class <- c("class_name", "n_images")
  expect_true(all(expected_columns_class %in% names(summary_class)))

  # Check that the data frame has non-zero rows
  expect_gt(nrow(summary_class), 0)

  # Check some specific values (replace with expected values based on your test data)
  # Example: Check if specific class_name exist in the output
  expect_true("Cryptomonadales" %in% summary_class$class_name)

  # Example: Check if n_images are calculated correctly
  expected_n_images_class <- 1  # Example value
  expect_equal(summary_class$n_images[1], expected_n_images_class)

  # Check if the function handles missing GPS data gracefully
  new_hdr_folder <- file.path(temp_dir, "new_hdr_folder")

  # Create a new folder with a copy of the HDR file
  dir.create(new_hdr_folder, showWarnings = FALSE)

  # Copy the HDR file to the new folder
  copy <- file.copy(file.path(hdr_folder, "D20220522T003051_IFCB134.hdr"),
                    file.path(new_hdr_folder, "D20220522T003051_IFCB134.hdr"))

  # Run the function with summarization level "sample" with missing GPS data
  summary_class <- ifcb_summarize_png_counts(png_folder, new_hdr_folder, sum_level = "sample", verbose = FALSE)

  # Expect NA values for GPS coordinates
  expect_true(is.na(summary_class$gpsLatitude[1]))
  expect_true(is.na(summary_class$gpsLongitude[1]))
})

test_that("ifcb_summarize_png_counts handles empty directories gracefully", {
  # Define empty directories for png and hdr
  empty_png_dir <- file.path(temp_dir, "empty_png")
  empty_hdr_dir <- file.path(temp_dir, "empty_hdr")

  dir.create(empty_png_dir)
  dir.create(empty_hdr_dir)

  # Run the function with empty png directory and expect an error
  expect_error(ifcb_summarize_png_counts(empty_png_dir, hdr_folder, sum_level = "sample", verbose = TRUE), "No subdirectories found in the PNG folder")

  # Run the function with empty hdr directory and expect an error
  expect_error(ifcb_summarize_png_counts(png_folder, empty_hdr_dir, sum_level = "sample", verbose = TRUE), "No HDR data found")
})

test_that("ifcb_summarize_png_counts handles invalid directories gracefully", {
  # Define invalid directories for png and hdr
  invalid_png_dir <- file.path(temp_dir, "invalid_png")
  invalid_hdr_dir <- file.path(temp_dir, "invalid_hdr")

  # Run the function with invalid directories and expect an error
  expect_error(ifcb_summarize_png_counts(invalid_png_dir, invalid_hdr_dir, sum_level = "sample", verbose = TRUE))
})

test_that("ifcb_summarize_png_counts calculates n_images correctly for different classes", {
  # Use test data to check specific calculations
  summary_class <- ifcb_summarize_png_counts(png_folder, hdr_folder, sum_level = "class", verbose = TRUE)

  # Check if n_images are calculated correctly for each class
  # Replace the following expected values with the actual expected values from your test data
  expected_class_counts <- dplyr::tibble(
    class_name = "Cryptomonadales",
    n_images = 1
  )

  expect_equal(summary_class, expected_class_counts)
})
