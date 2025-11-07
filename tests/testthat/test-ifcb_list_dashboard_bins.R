test_that("ifcb_list_dashboard_bins works", {
  # Skip the test if the internet connection is not available
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://ifcb-data.whoi.edu")

  bins <- ifcb_list_dashboard_bins("https://ifcb-data.whoi.edu/")

  # Basic checks
  expect_s3_class(bins, "data.frame")      # Should be a data.frame
  expect_gt(nrow(bins), 0)                 # Should have at least one row
  expect_gt(ncol(bins), 1)                 # Should have at least two columns
})
