test_that("ifcb_extract_classified_images works correctly with default parameters", {
  skip_on_cran()

  # Create a temporary directory
  temp_dir <- file.path(tempdir(), "ifcb_extract_classified_images")

  # Define the path to the test data zip file
  test_data_zip <- test_path("test_data/test_data.zip")
  expect_true(file.exists(test_data_zip))

  # Unzip the test data to the temporary directory
  unzip(test_data_zip, exdir = temp_dir)

  # Define the paths to the test data subfolders and files
  classified_folder <- file.path(temp_dir, "test_data/class/class2022_v1")
  roi_folder <- file.path(temp_dir, "test_data/data")
  out_folder <- file.path(temp_dir, "output_images")
  sample <- "D20220522T003051_IFCB134"

  # Ensure the test data directories and files exist
  expect_true(dir.exists(classified_folder))
  expect_true(dir.exists(roi_folder))

  # Create the output directory
  if (!dir.exists(out_folder)) {
    dir.create(out_folder)
  }

  # Run the function with default parameters
  ifcb_extract_classified_images(
    sample = sample,
    classified_folder = classified_folder,
    roi_folder = roi_folder,
    out_folder = out_folder,
    taxa = "All",
    threshold = "opt"
  )

  # Verify that the output directory contains the extracted images
  extracted_images <- list.files(out_folder, pattern = "\\.png$", full.names = TRUE, recursive = TRUE)
  expect_true(length(extracted_images) > 0)

  unlink(out_folder, recursive = TRUE)

  # Run the function by reading .mat files using Python
  ifcb_extract_classified_images(
    sample = sample,
    classified_folder = classified_folder,
    roi_folder = roi_folder,
    out_folder = out_folder,
    taxa = "All",
    threshold = "opt",
    use_python = TRUE
  )

  # Verify that the output directory contains the extracted images
  extracted_images_py <- list.files(out_folder, pattern = "\\.png$", full.names = TRUE, recursive = TRUE)

  # Check that the images extracted using Python are identical to those extracted using R
  expect_identical(extracted_images, extracted_images_py)

  # Clean up temporary files
  unlink(temp_dir, recursive = TRUE)
})

test_that("ifcb_extract_classified_images works correctly with specific taxa", {
  skip_on_cran()

  temp_dir <- file.path(tempdir(), "ifcb_extract_classified_images")
  test_data_zip <- test_path("test_data/test_data.zip")
  expect_true(file.exists(test_data_zip))
  unzip(test_data_zip, exdir = temp_dir)
  classified_folder <- file.path(temp_dir, "test_data/class/class2022_v1")
  roi_folder <- file.path(temp_dir, "test_data/data")
  out_folder <- file.path(temp_dir, "output_images")
  sample <- "D20220522T003051_IFCB134"

  expect_true(dir.exists(classified_folder))
  expect_true(dir.exists(roi_folder))

  if (!dir.exists(out_folder)) {
    dir.create(out_folder)
  }

  specific_taxa <- "Mesodinium_rubrum" # replace with actual taxa in your test data

  ifcb_extract_classified_images(
    sample = sample,
    classified_folder = classified_folder,
    roi_folder = roi_folder,
    out_folder = out_folder,
    taxa = specific_taxa,
    threshold = "opt"
  )

  extracted_images <- list.files(out_folder, pattern = "\\.png$", full.names = TRUE, recursive = TRUE)
  expect_true(length(extracted_images) > 0)

  unlink(temp_dir, recursive = TRUE)
})

test_that("ifcb_extract_classified_images handles missing classified file gracefully", {
  skip_on_cran()

  temp_dir <- file.path(tempdir(), "ifcb_extract_classified_images")
  test_data_zip <- test_path("test_data/test_data.zip")
  expect_true(file.exists(test_data_zip))
  unzip(test_data_zip, exdir = temp_dir)
  classified_folder <- file.path(temp_dir, "test_data/class/empty_folder") # Ensure this folder is empty or does not contain matching files
  roi_folder <- file.path(temp_dir, "test_data/data")
  out_folder <- file.path(temp_dir, "output_images")
  sample <- "D20220522T003051_IFCB134"

  if (!dir.exists(classified_folder)) {
    dir.create(classified_folder)
  }

  expect_true(dir.exists(classified_folder))
  expect_true(dir.exists(roi_folder))

  if (!dir.exists(out_folder)) {
    dir.create(out_folder)
  }

  expect_error(ifcb_extract_classified_images(
    sample = sample,
    classified_folder = classified_folder,
    roi_folder = roi_folder,
    out_folder = out_folder,
    taxa = "All",
    threshold = "opt"
  ), "Classified file for sample not found")

  unlink(temp_dir, recursive = TRUE)
})

test_that("ifcb_extract_classified_images handles multiple classified files gracefully", {
  skip_on_cran()

  temp_dir <- file.path(tempdir(), "ifcb_extract_classified_images")
  test_data_zip <- test_path("test_data/test_data.zip")
  expect_true(file.exists(test_data_zip))
  unzip(test_data_zip, exdir = temp_dir)
  classified_folder <- file.path(temp_dir, "test_data/class/class2022_v1")
  roi_folder <- file.path(temp_dir, "test_data/data")
  out_folder <- file.path(temp_dir, "output_images")
  sample <- "D20220522T003051_IFCB134"

  file.copy(file.path(classified_folder, "D20220522T003051_IFCB134_class_v1.mat"),
            file.path(classified_folder, "D20220522T003051_IFCB134_class_v2.mat"))

  expect_true(dir.exists(classified_folder))
  expect_true(dir.exists(roi_folder))

  if (!dir.exists(out_folder)) {
    dir.create(out_folder)
  }

  expect_error(ifcb_extract_classified_images(
    sample = sample,
    classified_folder = classified_folder,
    roi_folder = roi_folder,
    out_folder = out_folder,
    taxa = "All",
    threshold = "opt"
  ), "More than one matching class file in classified folder")

  unlink(temp_dir, recursive = TRUE)
})

test_that("ifcb_extract_classified_images works correctly with different thresholds", {
  skip_on_cran()

  temp_dir <- file.path(tempdir(), "ifcb_extract_classified_images")
  test_data_zip <- test_path("test_data/test_data.zip")
  expect_true(file.exists(test_data_zip))
  unzip(test_data_zip, exdir = temp_dir)
  classified_folder <- file.path(temp_dir, "test_data/class/class2022_v1")
  roi_folder <- file.path(temp_dir, "test_data/data")
  out_folder <- file.path(temp_dir, "output_images")
  sample <- "D20220522T003051_IFCB134"

  expect_true(dir.exists(classified_folder))
  expect_true(dir.exists(roi_folder))

  if (!dir.exists(out_folder)) {
    dir.create(out_folder)
  }

  thresholds <- c("none", "opt")

  for (threshold in thresholds) {
    ifcb_extract_classified_images(
      sample = sample,
      classified_folder = classified_folder,
      roi_folder = roi_folder,
      out_folder = out_folder,
      taxa = "All",
      threshold = threshold
    )

    extracted_images <- list.files(out_folder, pattern = "\\.png$", full.names = TRUE, recursive = TRUE)
    expect_true(length(extracted_images) > 0)
    unlink(out_folder, recursive = TRUE)
  }

  unlink(temp_dir, recursive = TRUE)
})

test_that("ifcb_extract_classified_images handles missing roi files gracefully", {
  skip_on_cran()

  temp_dir <- file.path(tempdir(), "ifcb_extract_classified_images")
  test_data_zip <- test_path("test_data/test_data.zip")
  expect_true(file.exists(test_data_zip))
  unzip(test_data_zip, exdir = temp_dir)
  classified_folder <- file.path(temp_dir, "test_data/class/class2022_v1")
  roi_folder <- file.path(temp_dir, "test_data/data")
  out_folder <- file.path(temp_dir, "output_images")
  sample <- "D20220522T003051_IFCB134"

  file.remove(file.path(roi_folder, "D20220522T003051_IFCB134.roi"))

  expect_true(dir.exists(classified_folder))
  expect_true(dir.exists(roi_folder))

  if (!dir.exists(out_folder)) {
    dir.create(out_folder)
  }

  expect_error(ifcb_extract_classified_images(
    sample = sample,
    classified_folder = classified_folder,
    roi_folder = roi_folder,
    out_folder = out_folder,
    taxa = "All",
    threshold = "opt"
  ), "ROI file for sample not found")

  unlink(temp_dir, recursive = TRUE)
})
