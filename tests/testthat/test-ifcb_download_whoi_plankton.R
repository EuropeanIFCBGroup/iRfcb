test_that("ifcb_download_whoi_plankton handles missing dataset years", {

  # Define the temporary directory for unzipping
  temp_dir <- file.path(tempdir(), "ifcb_download_whoi_plankton")

  # Download the WHOI-Plankton data for a non-existing year
  ifcb_download_whoi_plankton(2000, temp_dir)

  # Expect that the destination folder is empty
  expect_true(dir.exists(temp_dir))
  expect_equal(length(list.files(temp_dir)), 0)
})
