test_that("ifcb_download_whoi_plankton handles missing dataset years", {

  # Define the temporary directory for unzipping
  temp_dir <- file.path(tempdir(), "ifcb_download_whoi_plankton")

  # Download the WHOI-Plankton data for a non-existing year
  expect_error(ifcb_download_whoi_plankton(2000, temp_dir),
               "No valid years specified")

  # Expect that the destination folder is empty
  expect_true(!dir.exists(temp_dir))
  expect_equal(length(list.files(temp_dir)), 0)

  ifcb_download_whoi_plankton(2006, temp_dir, max_retries = 0)

  # Expect that the destination folder is empty
  expect_equal(length(list.files(temp_dir)), 0)

  # Clean up
  unlink(temp_dir, recursive = TRUE)
})
