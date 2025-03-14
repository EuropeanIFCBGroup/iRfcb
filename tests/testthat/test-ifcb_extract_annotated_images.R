test_that("ifcb_extract_annotated_images works correctly", {
  skip_on_cran()

  # Create a temporary directory
  temp_dir <- file.path(tempdir(), "ifcb_extract_annotated_images")

  # Define the path to the test data zip file
  test_data_zip <- test_path("test_data/test_data.zip")
  expect_true(file.exists(test_data_zip))

  # Unzip the test data to the temporary directory
  unzip(test_data_zip, exdir = temp_dir)

  # Define the paths to the test data subfolders and files
  manual_folder <- file.path(temp_dir, "test_data/manual")
  roi_folder <- file.path(temp_dir, "test_data/data")
  class2use_file <- file.path(temp_dir, "test_data/config/class2use.mat")
  out_folder <- file.path(temp_dir, "output_images")

  # Expect warning
  expect_warning(ifcb_extract_annotated_images(
    manual_folder = manual_folder,
    class2use_file = class2use_file,
    roi_folders = roi_folder,
    out_folder = out_folder,
    skip_class = NULL,
    verbose = FALSE
  ), "ROI file for sample D20220712T210855_IFCB134 not found. Skipping this sample."
  )

  # Remove unnecessary file
  file.remove(file.path(manual_folder, "D20220712T210855_IFCB134.mat"))

  # Ensure the test data directories and files exist
  expect_true(dir.exists(manual_folder))
  expect_true(dir.exists(roi_folder))
  expect_true(file.exists(class2use_file))

  # Create the output directory
  if (!dir.exists(out_folder)) {
    dir.create(out_folder)
  }

  # Run the function
  ifcb_extract_annotated_images(
    manual_folder = manual_folder,
    class2use_file = class2use_file,
    roi_folders = roi_folder,
    out_folder = out_folder,
    skip_class = NULL,
    verbose = FALSE
  )

  # Verify that the output directory contains the extracted images
  extracted_images <- list.files(out_folder, pattern = "\\.png$", full.names = TRUE, recursive = TRUE)
  expect_true(length(extracted_images) > 0)
})

test_that("ifcb_extract_annotated_images handles errors gracefully", {
  skip_on_cran()

  # Create a temporary directory
  temp_dir <- file.path(tempdir(), "ifcb_extract_annotated_images")

  # Define the path to the test data zip file
  test_data_zip <- test_path("test_data/test_data.zip")
  expect_true(file.exists(test_data_zip))

  # Unzip the test data to the temporary directory
  unzip(test_data_zip, exdir = temp_dir)

  # Define the paths to the test data subfolders and files
  manual_folder <- file.path(temp_dir, "test_data/manual")
  roi_folder <- file.path(temp_dir, "test_data/data")
  class2use_file <- file.path(temp_dir, "test_data/config/class2use.mat")
  out_folder <- file.path(temp_dir, "output_warning_images")

  # Expect warning
  expect_warning(ifcb_extract_annotated_images(
    manual_folder = manual_folder,
    class2use_file = class2use_file,
    roi_folders = roi_folder,
    out_folder = out_folder,
    skip_class = NULL,
    verbose = FALSE
  ), "ROI file for sample D20220712T210855_IFCB134 not found. Skipping this sample."
  )

  # Remove unnecessary file
  file.remove(file.path(manual_folder, "D20220712T210855_IFCB134.mat"))

  # Create the output directory
  if (!dir.exists(out_folder)) {
    dir.create(out_folder)
  }

  # Test error handling
  expect_error(ifcb_extract_annotated_images(
    manual_folder = "non-exisiting-folder",
    class2use_file = class2use_file,
    roi_folders = roi_folder,
    out_folder = out_folder,
    skip_class = NULL,
    verbose = FALSE
  ), "No manual files found in the specified directory."
  )

  # Run the function and expect deprecated warning
  lifecycle::expect_deprecated(
    ifcb_extract_annotated_images(
      manual_folder = manual_folder,
      class2use_file = class2use_file,
      roi_folder = roi_folder,
      out_folder = out_folder,
      skip_class = NULL,
      verbose = FALSE
    )
  )

  # Test error handling
  expect_error(ifcb_extract_annotated_images(
    manual_folder = manual_folder,
    class2use_file = class2use_file,
    roi_folders = roi_folder,
    out_folder = out_folder,
    skip_class = "non-exisiting-class",
    verbose = FALSE
  ), "None of the class names provided in skip_class were found in class2use."
  )

  # Clean up temporary files
  unlink(temp_dir, recursive = TRUE)
})
