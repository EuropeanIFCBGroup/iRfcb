library(testthat)
library(fs)  # For file system operations

# Define the setup function
setup_mock_directory <- function() {
  temp_dir <- tempdir()  # Use tempdir() to create a temporary directory

  # Create a subdirectory and some mock files
  dir_create(file.path(temp_dir, "subfolder"), recurse = TRUE)

  # Create some mock files
  writeLines("This is a test file.", file.path(temp_dir, "file1.txt"))
  writeLines("This is another test file.", file.path(temp_dir, "file2.txt"))
  writeLines("This is a subfolder test file.", file.path(temp_dir, "subfolder", "file3.txt"))

  return(temp_dir)
}

# Define test cases
test_that("ifcb_create_manifest creates MANIFEST.txt correctly", {
  # Setup mock directory
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE))  # Ensure temp_dir is removed after the test

  # Path to the expected manifest file
  manifest_path <- file.path(temp_dir, "MANIFEST.txt")

  # Call the function to create the manifest
  ifcb_create_manifest(temp_dir)

  # Check if the MANIFEST.txt file has been created
  expect_true(file.exists(manifest_path))

  # Read the content of the MANIFEST.txt file
  manifest_content <- readLines(manifest_path)

  # Expected content
  expected_content <- c(
    "file1.txt [21 bytes]",
    "file2.txt [27 bytes]",
    "subfolder/file3.txt [31 bytes]"
  )

  # Check if the content matches the expected content
  expect_equal(manifest_content, expected_content)
})

test_that("ifcb_create_manifest excludes existing MANIFEST.txt when specified", {
  # Setup mock directory
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE))  # Ensure temp_dir is removed after the test

  # Path to the manifest file
  manifest_path <- file.path(temp_dir, "MANIFEST.txt")

  # Create an initial MANIFEST.txt file
  writeLines("Initial MANIFEST content", manifest_path)

  # Call the function to create the manifest, excluding the existing MANIFEST.txt file
  ifcb_create_manifest(temp_dir, exclude_manifest = TRUE)

  # Read the content of the MANIFEST.txt file
  manifest_content <- readLines(manifest_path)

  # Expected content (should not include the initial MANIFEST.txt file)
  expected_content <- c(
    "file1.txt [21 bytes]",
    "file2.txt [27 bytes]",
    "subfolder/file3.txt [31 bytes]"
  )

  # Check if the content matches the expected content
  expect_equal(manifest_content, expected_content)
})

test_that("ifcb_create_manifest includes existing MANIFEST.txt when specified", {
  # Setup mock directory
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE))  # Ensure temp_dir is removed after the test

  # Path to the manifest file
  manifest_path <- file.path(temp_dir, "MANIFEST.txt")

  # Create an initial MANIFEST.txt file
  writeLines("Initial MANIFEST content", manifest_path)

  # Call the function to create the manifest, including the existing MANIFEST.txt file
  ifcb_create_manifest(temp_dir, exclude_manifest = FALSE)

  # Read the content of the MANIFEST.txt file
  manifest_content <- readLines(manifest_path)

  # Expected content (should include the initial MANIFEST.txt file)
  expected_content <- c(
    "MANIFEST.txt [25 bytes]",
    "file1.txt [21 bytes]",
    "file2.txt [27 bytes]",
    "subfolder/file3.txt [31 bytes]"
  )

  # Check if the content matches the expected content
  expect_equal(manifest_content, expected_content)
})
