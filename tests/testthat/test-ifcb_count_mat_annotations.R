library(testthat)
library(dplyr)
library(R.matlab)

test_that("ifcb_count_mat_annotations works correctly", {
  # Define paths to the test data
  test_data_zip <- test_path("test_data/test_data.zip")
  temp_dir <- tempdir()
  unzip(test_data_zip, exdir = temp_dir)

  # Define the paths for the manual folder and the class2use file
  manual_folder <- file.path(temp_dir, "test_data", "manual")
  class2use_file <- file.path(temp_dir, "test_data", "config", "class2use.mat")

  # Ensure that the .mat files and class2use file exist
  expect_true(dir.exists(manual_folder))
  expect_true(file.exists(class2use_file))

  # Run the function without skipping any classes
  result <- ifcb_count_mat_annotations(manual_folder, class2use_file)

  # Verify the structure of the result
  expect_s3_class(result, "data.frame")
  expect_named(result, c("class", "n"))
  expect_true(all(c("class", "n") %in% names(result)))

  # Run the function with skipping specific class IDs
  skip_ids <- 1
  result_skip_ids <- ifcb_count_mat_annotations(manual_folder, class2use_file, skip_class = skip_ids)

  # Verify the structure and content of the result
  expect_s3_class(result_skip_ids, "data.frame")
  expect_named(result_skip_ids, c("class", "n"))

  # Ensure that the skipped IDs do not appear in the result
  skipped_classes <- ifcb_get_mat_variable(class2use_file) %>%
    tibble::enframe(name = NULL, value = "class") %>%
    filter(seq_along(class) %in% skip_ids) %>%
    pull(class)
  expect_true(all(!result_skip_ids$class %in% skipped_classes))

  # Run the function with skipping a specific class name
  skip_names <- "unclassified"
  result_skip_names <- ifcb_count_mat_annotations(manual_folder, class2use_file, skip_class = skip_names)

  # Verify the structure and content of the result
  expect_s3_class(result_skip_names, "data.frame")
  expect_named(result_skip_names, c("class", "n"))

  # Ensure that the skipped class name does not appear in the result
  expect_true(all(!result_skip_names$class %in% skip_names))

  # Cleanup temporary files
  unlink(temp_dir, recursive = TRUE)
})

# Helper function to extract class2use from .mat file
ifcb_get_mat_variable <- function(file) {
  mat_data <- R.matlab::readMat(file)
  as.character(mat_data$class2use)
}
