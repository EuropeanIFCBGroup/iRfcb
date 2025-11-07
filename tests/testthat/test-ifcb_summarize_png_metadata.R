# Extract test data and define paths
zip_path <- test_path("test_data/test_data.zip")
temp_dir <- file.path(tempdir(), "ifcb_summarize_png_metadata")
unzip(zip_path, exdir = temp_dir)

# Define paths to the unzipped folders
png_folder <- file.path(temp_dir, "test_data", "png2")
hdr_folder <- file.path(temp_dir, "test_data", "data")
feature_folder <- file.path(temp_dir, "test_data", "features")

# Ensure the temporary directories are cleaned up after tests
on.exit({
  unlink(temp_dir, recursive = TRUE)
}, add = TRUE)

test_that("ifcb_summarize_png_metadata works correctly with sample data", {
  # Run the function with summarization level "sample"
  summary_sample <- ifcb_summarize_png_metadata(png_folder = png_folder,
                                                feature_folder = feature_folder,
                                                hdr_folder = hdr_folder)

  # Check that the returned object is a data frame
  expect_s3_class(summary_sample, "data.frame")

  # Check that the data frame contains the expected columns
  expected_columns_sample <- c("image", "ifcb_number", "timestamp", "date", "year", "month", "day", "time", "roi")
  expect_true(all(expected_columns_sample %in% names(summary_sample)))

  # Check that the data frame has non-zero rows
  expect_gt(nrow(summary_sample), 0)

  # Check some specific values (replace with expected values based on your test data)
  # Example: Check if specific sample and class_name exist in the output
  expect_true("D20220522T003051_IFCB134" %in% summary_sample$sample)
  expect_true("Mesodinium_rubrum" %in% summary_sample$subfolder)

  # Example: Check if n_images are calculated correctly
  expected_n_images <- 1  # Example value
  expect_equal(nrow(summary_sample), expected_n_images)

  expect_no_error(ifcb_summarize_png_metadata(png_folder))
})

test_that("ifcb_summarize_png_metadata handles empty directories gracefully", {
  # Define empty directories for png and hdr
  empty_png_dir <- file.path(temp_dir, "empty_png")
  empty_hdr_dir <- file.path(temp_dir, "empty_hdr")
  empty_feature_dir <- file.path(temp_dir, "empty_features")

  dir.create(empty_png_dir)
  dir.create(empty_hdr_dir)
  dir.create(empty_feature_dir)

  # Run the function with empty png directory and expect an error
  expect_error(ifcb_summarize_png_metadata(empty_png_dir), "No PNG files found in")

  # Run the function with empty hdr directory and expect a warning
  expect_warning(ifcb_summarize_png_metadata(png_folder,
                                             feature_folder = feature_folder,
                                             hdr_folder = empty_hdr_dir), "No HDR files found")

  # Run the function with empty hdr directory and expect a warning
  expect_warning(ifcb_summarize_png_metadata(png_folder,
                                             feature_folder = empty_feature_dir,
                                             hdr_folder = hdr_folder), "No feature files found")
})
