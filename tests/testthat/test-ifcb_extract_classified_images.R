library(testthat)
library(R.matlab)

test_that("ifcb_extract_classified_images works correctly", {
  # Create a temporary directory
  temp_dir <- tempdir()

  # Define the path to the test data zip file
  test_data_zip <- test_path("test_data/test_data.zip")
  expect_true(file.exists(test_data_zip))

  # Unzip the test data to the temporary directory
  unzip(test_data_zip, exdir = temp_dir)

  # Define the paths to the test data subfolders and files
  classified_folder <- file.path(temp_dir, "test_data/class/class2022_v1")
  roi_folder <- file.path(temp_dir, "test_data/data")
  class2use_file <- file.path(temp_dir, "test_data/config/class2use.mat")
  out_folder <- file.path(temp_dir, "output_images")
  sample <- "D20220522T003051_IFCB134"

  # Ensure the test data directories and files exist
  expect_true(dir.exists(classified_folder))
  expect_true(dir.exists(roi_folder))
  expect_true(file.exists(class2use_file))

  # Create the output directory
  if (!dir.exists(out_folder)) {
    dir.create(out_folder)
  }

  # Run the function
  ifcb_extract_classified_images(
    sample = sample,
    classified_folder = classified_folder,
    roi_folder = roi_folder,
    out_folder = out_folder,
    taxa = "All",  # or specify a particular taxa
    threshold = "opt"  # or specify another threshold
  )

  # Verify that the output directory contains the extracted images
  extracted_images <- list.files(out_folder, pattern = "\\.png$", full.names = TRUE, recursive = TRUE)
  expect_true(length(extracted_images) > 0)

  # Clean up temporary files
  unlink(temp_dir, recursive = TRUE)
})
