test_that("ifcb_classify_sample errors when roi_file does not exist", {
  expect_error(
    ifcb_classify_sample("nonexistent.roi"),
    "roi_file not found"
  )
})

test_that("ifcb_classify_sample returns empty data frame when no PNGs extracted", {
  # Create a fake ROI file so the file.exists check passes
  fake_roi <- tempfile(fileext = ".roi")
  file.create(fake_roi)
  on.exit(unlink(fake_roi), add = TRUE)

  # Mock ifcb_extract_pngs to do nothing (no PNGs created)
  mockery::stub(ifcb_classify_sample, "ifcb_extract_pngs", function(...) invisible(NULL))

  expect_warning(
    result <- ifcb_classify_sample(fake_roi, verbose = FALSE),
    "No PNG images were extracted"
  )

  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 0)
  expect_named(result, c("file_name", "class_name", "class_name_auto", "score", "model_name"))
})

test_that("ifcb_classify_sample strips trailing slashes from gradio_url", {
  fake_roi <- tempfile(fileext = ".roi")
  file.create(fake_roi)
  on.exit(unlink(fake_roi), add = TRUE)

  captured_url <- NULL

  # Mock ifcb_extract_pngs to create a fake PNG
  mockery::stub(ifcb_classify_sample, "ifcb_extract_pngs", function(roi_file, out_folder, ...) {
    png_path <- file.path(out_folder, basename(roi_file))
    png_dir <- file.path(out_folder, sub("\\.[^.]+$", "", basename(roi_file)))
    dir.create(png_dir, showWarnings = FALSE, recursive = TRUE)
    file.create(file.path(png_dir, "test_00001.png"))
  })

  # Mock ifcb_classify_images to capture the URL
  mockery::stub(ifcb_classify_sample, "ifcb_classify_images", function(png_files, gradio_url, ...) {
    captured_url <<- gradio_url
    data.frame(
      file_name = basename(png_files),
      class_name = "ClassA",
      class_name_auto = "ClassA",
      score = 0.9,
      model_name = "Test Model",
      stringsAsFactors = FALSE
    )
  })

  ifcb_classify_sample(fake_roi, gradio_url = "https://example.com///", verbose = FALSE)

  expect_equal(captured_url, "https://example.com")
})

test_that("ifcb_classify_sample passes arguments to ifcb_classify_images", {
  fake_roi <- tempfile(fileext = ".roi")
  file.create(fake_roi)
  on.exit(unlink(fake_roi), add = TRUE)

  captured_args <- list()

  # Mock ifcb_extract_pngs to create fake PNGs
  mockery::stub(ifcb_classify_sample, "ifcb_extract_pngs", function(roi_file, out_folder, ...) {
    png_dir <- file.path(out_folder, sub("\\.[^.]+$", "", basename(roi_file)))
    dir.create(png_dir, showWarnings = FALSE, recursive = TRUE)
    file.create(file.path(png_dir, "img_00001.png"))
    file.create(file.path(png_dir, "img_00002.png"))
  })

  # Mock ifcb_classify_images to capture arguments
  mockery::stub(ifcb_classify_sample, "ifcb_classify_images", function(png_files, gradio_url, top_n, model_name, verbose) {
    captured_args <<- list(
      n_files = length(png_files),
      gradio_url = gradio_url,
      top_n = top_n,
      model_name = model_name
    )
    data.frame(
      file_name = basename(png_files),
      class_name = "ClassA",
      class_name_auto = "ClassA",
      score = 0.9,
      model_name = model_name,
      stringsAsFactors = FALSE
    )
  })

  ifcb_classify_sample(
    fake_roi,
    gradio_url = "https://custom.url",
    top_n = 3,
    model_name = "Custom Model",
    verbose = FALSE
  )

  expect_equal(captured_args$n_files, 2)
  expect_equal(captured_args$gradio_url, "https://custom.url")
  expect_equal(captured_args$top_n, 3)
  expect_equal(captured_args$model_name, "Custom Model")
})

# ── Integration test (requires network access) ────────────────────────────────

test_that("ifcb_classify_sample classifies a real ROI file and returns non-NA results", {
  skip_on_cran()
  skip_if_offline()
  skip_if_resource_unavailable(
    "https://irfcb-classify.hf.space/gradio_api/call/predict_html"
  )

  test_data_zip <- test_path("test_data/test_data.zip")
  temp_dir <- file.path(tempdir(), "ifcb_classify_sample_integration")
  utils::unzip(test_data_zip, exdir = temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  roi_file <- file.path(temp_dir, "test_data", "data",
                        "D20220522T003051_IFCB134.roi")

  result <- ifcb_classify_sample(roi_file, verbose = FALSE)

  expect_true(is.data.frame(result))
  expect_named(result, c("file_name", "class_name", "class_name_auto", "score", "model_name"))
  expect_gt(nrow(result), 0)
  expect_false(anyNA(result$class_name),
               label = "class_name must have no NAs when API is reachable")
  expect_true(all(result$score >= 0 & result$score <= 1),
              label = "scores must be in [0, 1]")
})
