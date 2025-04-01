test_that("ifcb_download_test_data downloads and unzips files correctly", {
  # Check for internet connection and skip the test if offline
  skip_if_offline(host = "figshare.scilifelab.se")
  skip_on_cran()

  # Setup test environment
  temp_dir <- file.path(tempdir(), "ifcb_download_test_data")
  on.exit(unlink(temp_dir, recursive = TRUE))  # Ensure temp_dir is removed after the test

  # Non-existing directory
  temp_dir <- file.path(temp_dir, "temp")

  # Call the function to test error handling
  expect_error(ifcb_download_test_data(temp_dir, figshare_article = "Non-valid-article", max_retries = 2, sleep_time = 1), "Download failed after 2 attempts.")

  # Call the function to download and unzip test data
  ifcb_download_test_data(temp_dir)

  # Check if the files have been downloaded and extracted correctly
  zip_files <- list.files(temp_dir, pattern = "\\.zip$", full.names = TRUE, recursive = TRUE)
  expect_equal(length(zip_files), 0, info = "ZIP files should be removed after extraction")

  # Check if PNG files are extracted
  png_files <- list.files(file.path(temp_dir, "png"), pattern = "\\.png$", full.names = TRUE, recursive = TRUE)
  expect_gt(length(png_files), 0)

  # Check if MATLAB files are extracted
  mat_files <- list.files(file.path(temp_dir, "classified", "2023"), pattern = "\\.mat$", full.names = TRUE)
  expect_gt(length(mat_files), 0)

  summary_mat_files <- list.files(file.path(temp_dir, "classified", "2023", "summary"), pattern = "\\.mat$", full.names = TRUE)
  expect_gt(length(summary_mat_files), 0)

  # Check if text files are copied correctly
  correction_txt <- file.path(temp_dir, "manual", "correction", "Alexandrium_pseudogonyaulax_selected_images.txt")
  ferrybox_txt <- file.path(temp_dir, "ferrybox_data", "SveaFB_38059_20220501000100_20220531235800_OK.txt")

  expect_true(file.exists(correction_txt), info = "Correction text file not found")
  expect_true(file.exists(ferrybox_txt), info = "Ferrybox text file not found")
})
