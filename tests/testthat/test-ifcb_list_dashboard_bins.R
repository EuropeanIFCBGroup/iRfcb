test_that("ifcb_list_dashboard_bins is deprecated", {
  expect_warning(
    tryCatch(
      ifcb_list_dashboard_bins("https://example.invalid/", dataset_name = "mvco"),
      error = function(e) NULL
    ),
    class = "lifecycle_warning_deprecated"
  )
})

test_that("ifcb_list_dashboard_bins still parses a successful response", {
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://ifcb-data.whoi.edu/api/list_bins?dataset=mvco")

  bins <- suppressWarnings(
    ifcb_list_dashboard_bins("https://ifcb-data.whoi.edu/", dataset_name = "mvco")
  )

  expect_s3_class(bins, "data.frame")
  expect_gt(nrow(bins), 0)
  expect_gt(ncol(bins), 1)
})
