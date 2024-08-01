library(testthat)
library(fs)
library(zip)  # For unzipping files

# Define the setup function
setup_mock_directory <- function() {
  temp_dir <- tempdir()  # Use tempdir() to create a temporary directory
  test_data_zip <- test_path("test_data/test_data.zip")

  # Unzip the test data into the temporary directory
  unzip(test_data_zip, exdir = temp_dir)

  temp_dir
}

# Define test cases
test_that("ifcb_create_manifest creates MANIFEST.txt correctly", {
  # Setup mock directory
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE))  # Ensure temp_dir is removed after the test

  # Path to the expected manifest file
  manifest_path <- file.path(temp_dir, "test_data", "MANIFEST.txt")

  # Call the function to create the manifest
  ifcb_create_manifest(file.path(temp_dir, "test_data"))

  # Check if the MANIFEST.txt file has been created
  expect_true(file.exists(manifest_path))

  # Read the content of the MANIFEST.txt file
  manifest_content <- readLines(manifest_path)

  # Expected content
  expected_content <- c(
    "class/class2022_v1/D20220522T003051_IFCB134_class_v1.mat [1,552 bytes]",
    "config/class2use.mat [2,151 bytes]",
    "data/D20220522T000439_IFCB134.adc [1,688 bytes]",
    "data/D20220522T000439_IFCB134.hdr [3,283 bytes]",
    "data/D20220522T003051_IFCB134.adc [620 bytes]",
    "data/D20220522T003051_IFCB134.hdr [3,280 bytes]",
    "data/D20220522T003051_IFCB134.roi [30,848 bytes]",
    "data/D20230810T113059_IFCB134.adc [1,146,601 bytes]",
    "data/D20230810T113059_IFCB134.hdr [3,675 bytes]",
    "features/D20220522T003051_IFCB134_fea_v2.csv [8,356 bytes]",
    "manual/D20220522T003051_IFCB134.mat [10,872 bytes]",
    "manual/D20220712T210855_IFCB134.mat [15,216 bytes]",
    "png/Cryptomonadales/D20230810T113059_IFCB134_04108.png [3,280 bytes]"
  )

  # Check if the content matches the expected content
  expect_equal(manifest_content, expected_content)
})

test_that("ifcb_create_manifest excludes existing MANIFEST.txt when specified", {
  # Setup mock directory
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE))  # Ensure temp_dir is removed after the test

  # Path to the manifest file
  manifest_path <- file.path(temp_dir, "test_data", "MANIFEST.txt")

  # Create an initial MANIFEST.txt file
  writeLines("Initial MANIFEST content", manifest_path)

  # Call the function to create the manifest, excluding the existing MANIFEST.txt file
  ifcb_create_manifest(file.path(temp_dir, "test_data"), exclude_manifest = TRUE)

  # Read the content of the MANIFEST.txt file
  manifest_content <- readLines(manifest_path)

  # Expected content (should not include the initial MANIFEST.txt file)
  expected_content <- c(
    "class/class2022_v1/D20220522T003051_IFCB134_class_v1.mat [1,552 bytes]",
    "config/class2use.mat [2,151 bytes]",
    "data/D20220522T000439_IFCB134.adc [1,688 bytes]",
    "data/D20220522T000439_IFCB134.hdr [3,283 bytes]",
    "data/D20220522T003051_IFCB134.adc [620 bytes]",
    "data/D20220522T003051_IFCB134.hdr [3,280 bytes]",
    "data/D20220522T003051_IFCB134.roi [30,848 bytes]",
    "data/D20230810T113059_IFCB134.adc [1,146,601 bytes]",
    "data/D20230810T113059_IFCB134.hdr [3,675 bytes]",
    "features/D20220522T003051_IFCB134_fea_v2.csv [8,356 bytes]",
    "manual/D20220522T003051_IFCB134.mat [10,872 bytes]",
    "manual/D20220712T210855_IFCB134.mat [15,216 bytes]",
    "png/Cryptomonadales/D20230810T113059_IFCB134_04108.png [3,280 bytes]"
  )

  # Check if the content matches the expected content
  expect_equal(manifest_content, expected_content)
})

test_that("ifcb_create_manifest includes existing MANIFEST.txt when specified", {
  # Setup mock directory
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE))  # Ensure temp_dir is removed after the test

  # Path to the manifest file
  manifest_path <- file.path(temp_dir, "test_data", "MANIFEST.txt")

  # Create an initial MANIFEST.txt file
  writeLines("Initial MANIFEST content", manifest_path)

  # Call the function to create the manifest, including the existing MANIFEST.txt file
  ifcb_create_manifest(file.path(temp_dir, "test_data"), exclude_manifest = FALSE)

  # Read the content of the MANIFEST.txt file
  manifest_content <- readLines(manifest_path)

  # Expected content (should include the initial MANIFEST.txt file)
  expected_content <- c(
    "MANIFEST.txt [25 bytes]",
    "class/class2022_v1/D20220522T003051_IFCB134_class_v1.mat [1,552 bytes]",
    "config/class2use.mat [2,151 bytes]",
    "data/D20220522T000439_IFCB134.adc [1,688 bytes]",
    "data/D20220522T000439_IFCB134.hdr [3,283 bytes]",
    "data/D20220522T003051_IFCB134.adc [620 bytes]",
    "data/D20220522T003051_IFCB134.hdr [3,280 bytes]",
    "data/D20220522T003051_IFCB134.roi [30,848 bytes]",
    "data/D20230810T113059_IFCB134.adc [1,146,601 bytes]",
    "data/D20230810T113059_IFCB134.hdr [3,675 bytes]",
    "features/D20220522T003051_IFCB134_fea_v2.csv [8,356 bytes]",
    "manual/D20220522T003051_IFCB134.mat [10,872 bytes]",
    "manual/D20220712T210855_IFCB134.mat [15,216 bytes]",
    "png/Cryptomonadales/D20230810T113059_IFCB134_04108.png [3,280 bytes]"
  )

  # Check if the content matches the expected content
  expect_equal(manifest_content, expected_content)
})
