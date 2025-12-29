test_that("ifcb_zip_matlab works correctly", {

  # Create a temporary directory
  temp_dir <- file.path(tempdir(), "ifcb_zip_matlab")

  # Define the path to the test data zip file
  test_data_zip <- test_path("test_data/test_data.zip")
  expect_true(file.exists(test_data_zip))

  # Unzip the test data to the temporary directory
  unzip(test_data_zip, exdir = temp_dir)

  # Define the paths to the test data subfolders and files
  manual_folder <- file.path(temp_dir, "test_data/manual")
  features_folder <- file.path(temp_dir, "test_data/features")
  data_folder <- file.path(temp_dir, "test_data/data")
  class2use_file <- file.path(temp_dir, "test_data/config/class2use.mat")
  zip_filename <- file.path(temp_dir, "output", "test_output.zip")

  # Remove unnecessary file
  file.remove(file.path(manual_folder, "D20220712T210855_IFCB134.mat"))

  # Ensure the test data directories and files exist
  expect_true(dir.exists(manual_folder))
  expect_true(dir.exists(features_folder))
  expect_true(dir.exists(data_folder))
  expect_true(file.exists(class2use_file))

  # Create placeholder content for README files
  readme_file <- file.path(temp_dir, "README-template.md")
  writeLines("This is a default README template.\n<DATE>\n<VERSION>\n<E-MAIL>\n<ZIP_NAME>\n<YEAR_START>\n<YEAR_END>\n<YEAR>\n<N_IMAGES>\n<CLASSES>", readme_file)

  matlab_readme_file <- file.path(temp_dir, "MATLAB-template.md")
  writeLines("This is a default MATLAB README template.", matlab_readme_file)

  # Run the function
  ifcb_zip_matlab(
    manual_folder, features_folder, class2use_file, zip_filename,
    data_folder = data_folder,
    readme_file = readme_file,
    matlab_readme_file = matlab_readme_file,
    email_address = "test@example.com",
    version = "1.0",
    print_progress = TRUE
  )

  # Verify that the zip file was created
  expect_true(file.exists(zip_filename))

  # List the contents of the zip file using zip::zip_list
  zip_contents <- zip::zip_list(zip_filename)

  # Define expected manual file in the zip archive
  expected_file <- list.files(manual_folder, pattern = "\\.mat$", full.names = TRUE, recursive = FALSE)

  # Define list of expected files in the zip archive based on manual file
  expected_files <- c(
    basename(expected_file),
    gsub("mat", "hdr", basename(expected_file)),
    gsub("mat", "adc", basename(expected_file)),
    gsub("mat", "roi", basename(expected_file)),
    gsub(".mat", "_fea_v2.csv", basename(expected_file)),
    "README.md",
    "MANIFEST.txt"
  )

  # Verify the zip file contains the expected files
  for (file in expected_files) {
    expect_true(basename(file) %in% basename(zip_contents$filename))
  }

  # Clean up temporary files
  unlink(temp_dir, recursive = TRUE)
})

test_that("ifcb_zip_matlab fails gracefully", {

  # Create a temporary directory
  temp_dir <- file.path(tempdir(), "ifcb_zip_matlab")

  if (!dir.exists(temp_dir)) {
    dir.create(temp_dir, recursive = TRUE)
  }

  temp_file <- file.path(temp_dir, "file.md")
  file.create(temp_file)

  # Run the function
  expect_error(ifcb_zip_matlab(
    manual_folder = "not_a_dir",
    features_folder = temp_dir,
    class2use_file = temp_dir,
    zip_filename = "test.zip",
    data_folder = temp_dir,
    readme_file = temp_file,
    matlab_readme_file = temp_file
  ),
  "Manual folder does not exist")

  expect_error(ifcb_zip_matlab(
    manual_folder = temp_dir,
    features_folder = "not_a_dir",
    class2use_file = temp_dir,
    zip_filename = "test.zip",
    data_folder = temp_dir,
    readme_file = temp_file,
    matlab_readme_file = temp_file
  ),
  "Feature folder does not exist")

  expect_error(ifcb_zip_matlab(
    manual_folder = temp_dir,
    features_folder = temp_dir,
    class2use_file = temp_dir,
    zip_filename = "test.zip",
    data_folder = "not_a_dir",
    readme_file = temp_file,
    matlab_readme_file = temp_file
  ),
  "Data folder does not exist")

  expect_error(ifcb_zip_matlab(
    manual_folder = temp_dir,
    features_folder = temp_dir,
    class2use_file = temp_dir,
    zip_filename = "test.zip",
    data_folder = temp_dir,
    readme_file = "not_a_file",
    matlab_readme_file = temp_file
  ),
  "README file does not exist")

  expect_error(ifcb_zip_matlab(
    manual_folder = temp_dir,
    features_folder = temp_dir,
    class2use_file = temp_dir,
    zip_filename = "test.zip",
    data_folder = temp_dir,
    readme_file = temp_file,
    matlab_readme_file = "not_a_file"
  ),
  "MATLAB README file does not exist")
})


test_that("helpers works correctly", {

  # Create a temporary directory
  temp_dir <- file.path(tempdir(), "split_large_zip")
  dir.create(temp_dir, showWarnings = FALSE)

  # Define the path to the test data zip file
  test_data_zip <- test_path("test_data/test_data.zip")

  # Copy the test data zip file to the temporary directory
  copy <- file.copy(test_data_zip, file.path(temp_dir, "test_data.zip"))

  # Split the test data zip file
  split_large_zip(file.path(temp_dir, "test_data.zip"), 500)

  # Verify that the zip file was not split
  expect_equal(length(list.files(temp_dir)), 1)

  # Verify that the the function returns an error when the specified zip file does not exist
  expect_error(suppressWarnings(split_large_zip(file.path(temp_dir, "not_a_file.zip"), 500)),
               "The specified zip file does not exist")

  # Verify that the zip file was not split
  expect_equal(length(list.files(temp_dir)), 1)

  # Clean up temporary files
  unlink(temp_dir, recursive = TRUE)
})
