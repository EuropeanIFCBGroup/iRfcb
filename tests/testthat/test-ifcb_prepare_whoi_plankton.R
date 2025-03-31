test_that("ifcb_prepare_whoi_plankton throws errors", {
  # Skip if Python is not available
  skip_if_no_scipy()

  # Check error
  expect_error(ifcb_prepare_whoi_plankton(2,
                                          "not_a_dir",
                                          "not_a_dir",
                                          "not_a_dir",
                                          "not_a_file"),
               "No valid years specified.")

  # Check error
  expect_error(ifcb_prepare_whoi_plankton(2,
                                          "not_a_dir",
                                          "not_a_dir",
                                          "not_a_dir",
                                          "not_a_file",
                                          download_features = TRUE),
               "`features_folder` must be specified when `download_features = TRUE`")

  # Check error
  expect_error(ifcb_prepare_whoi_plankton(2,
                                          "not_a_dir",
                                          "not_a_dir",
                                          "not_a_dir",
                                          "not_a_file",
                                          download_blobs = TRUE),
               "`blobs_folder` must be specified when `download_blobs = TRUE`")

})
