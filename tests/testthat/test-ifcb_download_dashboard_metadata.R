test_that("ifcb_download_dashboard_metadata works", {
  # Skip the test if the internet connection is not available
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://ifcb-data.whoi.edu")

  # Download metadata for a smaller dataset
  metadata <- ifcb_download_dashboard_metadata("https://ifcb-data.whoi.edu/", "NAAMES")

  # Basic checks
  expect_s3_class(metadata, "data.frame")      # Should be a data.frame
  expect_gt(nrow(metadata), 0)                 # Should have at least one row
  expect_gt(ncol(metadata), 1)                 # Should have at least two columns
})
