test_that("ifcb_classify_sample errors when roi_file does not exist", {
  expect_error(
    ifcb_classify_sample("nonexistent.roi"),
    "roi_file not found"
  )
})

# ── Integration test (requires network access) ────────────────────────────────

test_that("ifcb_classify_sample classifies a real ROI file and returns non-NA results", {
  skip_on_cran()
  skip_if_offline()
  skip_if_resource_unavailable(
    "https://ifcb.serve.scilifelab.se/gradio_api/call/predict_html"
  )

  test_data_zip <- test_path("test_data/test_data.zip")
  temp_dir <- file.path(tempdir(), "ifcb_classify_sample_integration")
  unzip(test_data_zip, exdir = temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  roi_file <- file.path(temp_dir, "test_data", "data",
                        "D20220522T003051_IFCB134.roi")

  result <- ifcb_classify_sample(roi_file, verbose = FALSE)

  expect_true(is.data.frame(result))
  expect_named(result, c("file_name", "class_name", "score"))
  expect_gt(nrow(result), 0)
  expect_false(anyNA(result$class_name),
               label = "class_name must have no NAs when API is reachable")
  expect_true(all(result$score >= 0 & result$score <= 1),
              label = "scores must be in [0, 1]")
})
