# Create a temporary directory
temp_dir <- file.path(tempdir(), "ifcb_zip_images_by_class")

# Define the path to the test data zip file
test_data_zip <- test_path("test_data/test_data.zip")

# Unzip the test data to the temporary directory
unzip(test_data_zip, exdir = temp_dir)

# Define the paths to the test data subfolders
image_folder <- file.path(temp_dir, "test_data/png")

test_that("Basic functionality: zips a single image", {
  output_dir <- file.path(tempdir(), "zips_basic")
  unlink(output_dir, recursive = TRUE)

  ifcb_zip_images_by_class(
    image_folder = image_folder,
    output_dir = output_dir,
    n_images = NULL,
    quiet = FALSE
  )

  zip_files <- list.files(output_dir, pattern = "\\.zip$", full.names = TRUE)
  expect_length(zip_files, 1)

  # Check that the zip contains the single PNG file
  contents <- zip::zip_list(zip_files[1])$filename
  expect_true(any(grepl("\\.png$", contents)))
})

test_that("n_images parameter randomly samples images", {
  output_dir <- file.path(tempdir(), "zips_n_images")
  unlink(output_dir, recursive = TRUE)

  # With only one image, the result should be identical
  ifcb_zip_images_by_class(
    image_folder = image_folder,
    output_dir = output_dir,
    n_images = 1,
    quiet = TRUE
  )

  zip_files <- list.files(output_dir, pattern = "\\.zip$", full.names = TRUE)
  expect_length(zip_files, 1)
  contents <- zip::zip_list(zip_files[1])$filename
  expect_true(any(grepl("\\.png$", contents)))
})

test_that("quiet suppresses progress output", {
  output_dir <- file.path(tempdir(), "zips_quiet")
  unlink(output_dir, recursive = TRUE)

  expect_silent(
    ifcb_zip_images_by_class(
      image_folder = image_folder,
      output_dir = output_dir,
      n_images = NULL,
      quiet = TRUE
    )
  )
})

test_that("handles empty subdirectory without error", {
  empty_dir <- file.path(tempdir(), "empty_subdir")
  dir.create(empty_dir, showWarnings = FALSE)

  output_dir <- file.path(tempdir(), "zips_empty")
  unlink(output_dir, recursive = TRUE)

  expect_message(
    ifcb_zip_images_by_class(
      image_folder = empty_dir,
      output_dir = output_dir,
      n_images = NULL,
      quiet = FALSE
    ),
    regexp = "No subdirectories found"
  )
})

test_that("non-existent image_folder throws error", {
  output_dir <- file.path(tempdir(), "zips_fail")
  unlink(output_dir, recursive = TRUE)

  expect_error(
    ifcb_zip_images_by_class(
      image_folder = "non_existent_folder",
      output_dir = output_dir,
      n_images = NULL
    ),
    regexp = "Image folder does not exist"
  )
})

test_that("creates output directory if it does not exist", {
  output_dir <- file.path(tempdir(), "zips_newdir")
  unlink(output_dir, recursive = TRUE)

  ifcb_zip_images_by_class(
    image_folder = image_folder,
    output_dir = output_dir,
    n_images = NULL,
    quiet = TRUE
  )

  expect_true(dir.exists(output_dir))
  expect_length(list.files(output_dir, pattern = "\\.zip$"), 1)
})

# Clean up temporary files
unlink(temp_dir, recursive = TRUE)
