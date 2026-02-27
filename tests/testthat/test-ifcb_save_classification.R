# ── Unit test: error on missing ROI file ──────────────────────────────────────

test_that("ifcb_save_classification errors when roi_file does not exist", {
  expect_error(
    ifcb_save_classification("nonexistent.roi", output_folder = tempdir()),
    "roi_file not found"
  )
})

# ── Unit test: error on invalid format ────────────────────────────────────────

test_that("ifcb_save_classification errors on invalid format", {
  fake_roi <- tempfile(fileext = ".roi")
  file.create(fake_roi)
  on.exit(unlink(fake_roi), add = TRUE)

  expect_error(
    ifcb_save_classification(fake_roi, output_folder = tempdir(), format = "xyz"),
    "'arg' should be one of"
  )
})

# ── Unit test: error when no PNGs extracted ───────────────────────────────────

test_that("ifcb_save_classification errors when no PNGs are extracted", {
  fake_roi <- tempfile(fileext = ".roi")
  file.create(fake_roi)
  on.exit(unlink(fake_roi), add = TRUE)

  mockery::stub(ifcb_save_classification, "ifcb_extract_pngs", function(...) invisible(NULL))

  expect_error(
    ifcb_save_classification(fake_roi, output_folder = tempdir(), verbose = FALSE),
    "No PNG images were extracted"
  )
})

# ── Unit test: HDF5 round-trip ────────────────────────────────────────────────

test_that("HDF5 round-trip: write mock scores, read back and verify", {
  skip_if_not_installed("hdf5r")

  h5_path <- tempfile(fileext = ".h5")
  on.exit(unlink(h5_path), add = TRUE)

  # Mock data
  class_labels <- c("ClassA", "ClassB", "ClassC")
  roi_numbers <- c(1L, 5L, 10L)
  score_matrix <- matrix(
    c(0.8, 0.1, 0.1,
      0.2, 0.7, 0.1,
      0.3, 0.3, 0.4),
    nrow = 3, byrow = TRUE
  )
  thresholds_vec <- c(0.5, 0.6, 0.5)
  classifier_name <- "Test Model"
  class_labels_auto <- c("ClassA", "ClassB", "ClassC")
  class_above_threshold <- c("ClassA", "ClassB", "unclassified")

  # Write HDF5
  h5file <- hdf5r::H5File$new(h5_path, mode = "w")
  h5file[["output_scores"]] <- score_matrix
  h5file[["class_labels"]] <- class_labels
  h5file[["roi_numbers"]] <- roi_numbers
  h5file[["classifierName"]] <- classifier_name
  h5file[["class_labels_auto"]] <- class_labels_auto
  h5file[["class_labels_above_threshold"]] <- class_above_threshold
  h5file[["thresholds"]] <- thresholds_vec
  h5file$close_all()

  # Read back
  h5read <- hdf5r::H5File$new(h5_path, mode = "r")
  on.exit(h5read$close_all(), add = TRUE)

  expect_equal(h5read[["output_scores"]]$read(), score_matrix)
  expect_equal(h5read[["class_labels"]]$read(), class_labels)
  expect_equal(h5read[["roi_numbers"]]$read(), roi_numbers)
  expect_equal(h5read[["classifierName"]]$read(), classifier_name)
  expect_equal(h5read[["class_labels_auto"]]$read(), class_labels_auto)
  expect_equal(h5read[["class_labels_above_threshold"]]$read(), class_above_threshold)
  expect_equal(h5read[["thresholds"]]$read(), thresholds_vec)
})

# ── Unit test: CSV output with mocked Gradio API ─────────────────────────────

test_that("ifcb_save_classification writes valid CSV with mocked API", {
  fake_roi <- tempfile(fileext = ".roi")
  file.create(fake_roi)
  out_dir <- file.path(tempdir(), "csv_test_output")
  on.exit({
    unlink(fake_roi)
    unlink(out_dir, recursive = TRUE)
  }, add = TRUE)

  # Mock ifcb_extract_pngs to create fake PNGs with proper IFCB naming
  mockery::stub(ifcb_save_classification, "ifcb_extract_pngs", function(roi_file, out_folder, ...) {
    dir.create(out_folder, showWarnings = FALSE, recursive = TRUE)
    sample_name <- sub("\\.[^.]+$", "", basename(roi_file))
    file.create(file.path(out_folder, paste0(sample_name, "_00001.png")))
    file.create(file.path(out_folder, paste0(sample_name, "_00005.png")))
  })

  # Mock gradio_upload_file
  mockery::stub(ifcb_save_classification, "gradio_upload_file", function(...) "/tmp/server/file.png")

  # Mock gradio_predict_scores to return scores for 3 classes
  mock_class_labels <- c("ClassA", "ClassB", "ClassC")
  call_count <- 0L
  mockery::stub(ifcb_save_classification, "gradio_predict_scores", function(gradio_url, image_data, model_name) {
    call_count <<- call_count + 1L
    if (call_count == 1L) {
      list(class_labels = mock_class_labels, scores = c(0.8, 0.1, 0.1))
    } else {
      list(class_labels = mock_class_labels, scores = c(0.2, 0.7, 0.1))
    }
  })

  # Mock gradio_get_thresholds
  mockery::stub(ifcb_save_classification, "gradio_get_thresholds", function(gradio_url, model_name) {
    thresholds <- c(ClassA = 0.5, ClassB = 0.5, ClassC = 0.5)
    list(class_labels = mock_class_labels, thresholds = thresholds, model_name = model_name)
  })

  result_path <- ifcb_save_classification(
    fake_roi,
    output_folder = out_dir,
    format = "csv",
    verbose = FALSE
  )

  expect_true(file.exists(result_path))
  expect_match(result_path, "\\.csv$")

  # Read and verify CSV contents
  csv_df <- utils::read.csv(result_path, stringsAsFactors = FALSE)
  expect_named(csv_df, c("file_name", "class_name", "class_name_auto", "score"))
  expect_equal(nrow(csv_df), 2)

  # First ROI: ClassA wins with 0.8 (above 0.5 threshold)
  expect_equal(csv_df$class_name_auto[1], "ClassA")
  expect_equal(csv_df$class_name[1], "ClassA")
  expect_equal(csv_df$score[1], 0.8)

  # Second ROI: ClassB wins with 0.7 (above 0.5 threshold)
  expect_equal(csv_df$class_name_auto[2], "ClassB")
  expect_equal(csv_df$class_name[2], "ClassB")
  expect_equal(csv_df$score[2], 0.7)

  # File names should be properly formatted
  expect_match(csv_df$file_name[1], "_00001\\.png$")
  expect_match(csv_df$file_name[2], "_00005\\.png$")
})

# ── Unit test: CSV threshold-applied class becomes unclassified ───────────────

test_that("ifcb_save_classification marks below-threshold predictions as unclassified in CSV", {
  fake_roi <- tempfile(fileext = ".roi")
  file.create(fake_roi)
  out_dir <- file.path(tempdir(), "csv_threshold_test")
  on.exit({
    unlink(fake_roi)
    unlink(out_dir, recursive = TRUE)
  }, add = TRUE)

  mockery::stub(ifcb_save_classification, "ifcb_extract_pngs", function(roi_file, out_folder, ...) {
    dir.create(out_folder, showWarnings = FALSE, recursive = TRUE)
    sample_name <- sub("\\.[^.]+$", "", basename(roi_file))
    file.create(file.path(out_folder, paste0(sample_name, "_00001.png")))
  })

  mockery::stub(ifcb_save_classification, "gradio_upload_file", function(...) "/tmp/server/file.png")

  # Return low scores - winning class score below threshold
  mockery::stub(ifcb_save_classification, "gradio_predict_scores", function(...) {
    list(class_labels = c("ClassA", "ClassB"), scores = c(0.4, 0.3))
  })

  # Set threshold at 0.5 - the winning score of 0.4 should be below
  mockery::stub(ifcb_save_classification, "gradio_get_thresholds", function(gradio_url, model_name) {
    list(
      class_labels = c("ClassA", "ClassB"),
      thresholds = c(ClassA = 0.5, ClassB = 0.5),
      model_name = model_name
    )
  })

  result_path <- ifcb_save_classification(
    fake_roi,
    output_folder = out_dir,
    format = "csv",
    verbose = FALSE
  )

  csv_df <- utils::read.csv(result_path, stringsAsFactors = FALSE)

  # Winning class is ClassA (0.4) but below threshold (0.5)
  expect_equal(csv_df$class_name_auto[1], "ClassA")
  expect_equal(csv_df$class_name[1], "unclassified")
  expect_equal(csv_df$score[1], 0.4)
})

# ── Unit test: HDF5 output with mocked Gradio API ────────────────────────────

test_that("ifcb_save_classification writes valid HDF5 with mocked API", {
  skip_if_not_installed("hdf5r")

  fake_roi <- tempfile(fileext = ".roi")
  file.create(fake_roi)
  out_dir <- file.path(tempdir(), "h5_mock_test")
  on.exit({
    unlink(fake_roi)
    unlink(out_dir, recursive = TRUE)
  }, add = TRUE)

  mock_class_labels <- c("Diatom", "Dino", "Ciliate")

  mockery::stub(ifcb_save_classification, "ifcb_extract_pngs", function(roi_file, out_folder, ...) {
    dir.create(out_folder, showWarnings = FALSE, recursive = TRUE)
    sample_name <- sub("\\.[^.]+$", "", basename(roi_file))
    file.create(file.path(out_folder, paste0(sample_name, "_00003.png")))
    file.create(file.path(out_folder, paste0(sample_name, "_00007.png")))
  })

  mockery::stub(ifcb_save_classification, "gradio_upload_file", function(...) "/tmp/server/file.png")

  call_count <- 0L
  mockery::stub(ifcb_save_classification, "gradio_predict_scores", function(...) {
    call_count <<- call_count + 1L
    if (call_count == 1L) {
      list(class_labels = mock_class_labels, scores = c(0.9, 0.05, 0.05))
    } else {
      list(class_labels = mock_class_labels, scores = c(0.1, 0.2, 0.7))
    }
  })

  mockery::stub(ifcb_save_classification, "gradio_get_thresholds", function(gradio_url, model_name) {
    list(
      class_labels = mock_class_labels,
      thresholds = c(Diatom = 0.5, Dino = 0.5, Ciliate = 0.5),
      model_name = model_name
    )
  })

  result_path <- ifcb_save_classification(
    fake_roi,
    output_folder = out_dir,
    format = "h5",
    verbose = FALSE
  )

  expect_true(file.exists(result_path))
  expect_match(result_path, "_class\\.h5$")

  # Read back and verify
  h5file <- hdf5r::H5File$new(result_path, mode = "r")
  on.exit(h5file$close_all(), add = TRUE)

  expect_true("output_scores" %in% names(h5file))
  expect_true("class_labels" %in% names(h5file))
  expect_true("roi_numbers" %in% names(h5file))
  expect_true("classifier_name" %in% names(h5file))
  expect_true("class_name_auto" %in% names(h5file))
  expect_true("class_name" %in% names(h5file))
  expect_true("thresholds" %in% names(h5file))

  scores <- h5file[["output_scores"]]$read()
  labels <- h5file[["class_labels"]]$read()
  rois <- h5file[["roi_numbers"]]$read()
  thresholds <- h5file[["thresholds"]]$read()
  auto_classes <- h5file[["class_name_auto"]]$read()
  threshold_classes <- h5file[["class_name"]]$read()

  expect_true(is.matrix(scores))
  n_rois <- length(rois)
  n_classes <- length(labels)
  # HDF5 may transpose the matrix; check that dimensions match in either order
  score_dims <- sort(dim(scores))
  expect_equal(score_dims, sort(c(n_rois, n_classes)))
  expect_equal(labels, mock_class_labels)
  expect_equal(rois, c(3L, 7L))
  expect_equal(length(thresholds), 3)
  expect_true(all(scores >= 0 & scores <= 1))

  # Verify winning classes
  expect_equal(auto_classes, c("Diatom", "Ciliate"))
  expect_equal(threshold_classes, c("Diatom", "Ciliate"))
})

# ── Unit test: MAT output with mocked Gradio API ─────────────────────────────

test_that("ifcb_save_classification writes valid MAT file with mocked API", {
  skip_on_cran()
  skip_if_no_python()
  skip_if_no_scipy()

  fake_roi <- tempfile(fileext = ".roi")
  file.create(fake_roi)
  out_dir <- file.path(tempdir(), "mat_mock_test")
  on.exit({
    unlink(fake_roi)
    unlink(out_dir, recursive = TRUE)
  }, add = TRUE)

  mock_class_labels <- c("ClassA", "ClassB", "ClassC")

  mockery::stub(ifcb_save_classification, "ifcb_extract_pngs", function(roi_file, out_folder, ...) {
    dir.create(out_folder, showWarnings = FALSE, recursive = TRUE)
    sample_name <- sub("\\.[^.]+$", "", basename(roi_file))
    file.create(file.path(out_folder, paste0(sample_name, "_00002.png")))
    file.create(file.path(out_folder, paste0(sample_name, "_00004.png")))
  })

  mockery::stub(ifcb_save_classification, "gradio_upload_file", function(...) "/tmp/server/file.png")

  call_count <- 0L
  mockery::stub(ifcb_save_classification, "gradio_predict_scores", function(...) {
    call_count <<- call_count + 1L
    if (call_count == 1L) {
      list(class_labels = mock_class_labels, scores = c(0.7, 0.2, 0.1))
    } else {
      list(class_labels = mock_class_labels, scores = c(0.1, 0.3, 0.6))
    }
  })

  mockery::stub(ifcb_save_classification, "gradio_get_thresholds", function(gradio_url, model_name) {
    list(
      class_labels = mock_class_labels,
      thresholds = c(ClassA = 0.5, ClassB = 0.5, ClassC = 0.8),
      model_name = model_name
    )
  })

  result_path <- ifcb_save_classification(
    fake_roi,
    output_folder = out_dir,
    format = "mat",
    verbose = FALSE
  )

  expect_true(file.exists(result_path))
  expect_match(result_path, "_class_v1\\.mat$")

  # Read back the MAT file with R.matlab
  mat_data <- R.matlab::readMat(result_path)

  # Verify expected fields exist
  expect_true("class2useTB" %in% names(mat_data))
  expect_true("TBscores" %in% names(mat_data))
  expect_true("roinum" %in% names(mat_data))
  expect_true("TBclass" %in% names(mat_data))
  expect_true("TBclass.above.threshold" %in% names(mat_data))
  expect_true("classifierName" %in% names(mat_data))

  # Verify score matrix dimensions (2 ROIs x 3 classes)
  tb_scores <- mat_data$TBscores
  expect_equal(nrow(tb_scores), 2)
  expect_equal(ncol(tb_scores), 3)
  expect_true(all(tb_scores >= 0 & tb_scores <= 1))

  # Verify ROI numbers
  roinum <- as.integer(mat_data$roinum)
  expect_equal(roinum, c(2L, 4L))

  # Verify class2useTB has classes + "unclassified" appended
  class2use <- unlist(mat_data$class2useTB)
  expect_equal(length(class2use), 4)  # 3 classes + "unclassified"
  expect_equal(unname(class2use[4]), "unclassified")

  # Verify winning classes
  tb_class <- unname(unlist(mat_data$TBclass))
  expect_equal(tb_class, c("ClassA", "ClassC"))

  # ROI 1: ClassA wins with 0.7 >= 0.5 threshold -> ClassA
  # ROI 2: ClassC wins with 0.6 < 0.8 threshold -> unclassified
  tb_class_above <- unname(unlist(mat_data$TBclass.above.threshold))
  expect_equal(tb_class_above, c("ClassA", "unclassified"))
})

# ── Unit test: output directory is created ────────────────────────────────────

test_that("ifcb_save_classification creates output directory if missing", {
  fake_roi <- tempfile(fileext = ".roi")
  file.create(fake_roi)
  out_dir <- file.path(tempdir(), "nested", "new", "dir")
  on.exit({
    unlink(fake_roi)
    unlink(file.path(tempdir(), "nested"), recursive = TRUE)
  }, add = TRUE)

  mockery::stub(ifcb_save_classification, "ifcb_extract_pngs", function(roi_file, out_folder, ...) {
    dir.create(out_folder, showWarnings = FALSE, recursive = TRUE)
    sample_name <- sub("\\.[^.]+$", "", basename(roi_file))
    file.create(file.path(out_folder, paste0(sample_name, "_00001.png")))
  })

  mockery::stub(ifcb_save_classification, "gradio_upload_file", function(...) "/tmp/server/file.png")

  mockery::stub(ifcb_save_classification, "gradio_predict_scores", function(...) {
    list(class_labels = c("ClassA"), scores = c(0.9))
  })

  mockery::stub(ifcb_save_classification, "gradio_get_thresholds", function(gradio_url, model_name) {
    list(
      class_labels = c("ClassA"),
      thresholds = c(ClassA = 0.5),
      model_name = model_name
    )
  })

  expect_false(dir.exists(out_dir))

  result_path <- ifcb_save_classification(
    fake_roi,
    output_folder = out_dir,
    format = "csv",
    verbose = FALSE
  )

  expect_true(dir.exists(out_dir))
  expect_true(file.exists(result_path))
})

# ── Integration test (requires network access) ────────────────────────────────

test_that("ifcb_save_classification produces a valid HDF5 file", {
  skip_on_cran()
  skip_if_offline()
  skip_if_not_installed("hdf5r")
  skip_if_resource_unavailable(
    "https://irfcb-classify.hf.space/gradio_api/call/predict_scores"
  )

  test_data_zip <- test_path("test_data/test_data.zip")
  temp_dir <- file.path(tempdir(), "ifcb_save_classification_integration")
  utils::unzip(test_data_zip, exdir = temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  roi_file <- file.path(temp_dir, "test_data", "data",
                        "D20220522T003051_IFCB134.roi")

  out_dir <- file.path(temp_dir, "output")

  result_path <- ifcb_save_classification(
    roi_file,
    output_folder = out_dir,
    verbose = FALSE
  )

  h5_path <- file.path(out_dir, "D20220522T003051_IFCB134_class.h5")
  expect_true(file.exists(h5_path))
  expect_equal(result_path, h5_path)

  # Verify HDF5 contents
  h5file <- hdf5r::H5File$new(h5_path, mode = "r")
  on.exit(h5file$close_all(), add = TRUE)

  expect_true("output_scores" %in% names(h5file))
  expect_true("class_labels" %in% names(h5file))
  expect_true("roi_numbers" %in% names(h5file))
  expect_true("classifier_name" %in% names(h5file))
  expect_true("class_name_auto" %in% names(h5file))
  expect_true("class_name" %in% names(h5file))
  expect_true("thresholds" %in% names(h5file))

  scores <- h5file[["output_scores"]]$read()
  labels <- h5file[["class_labels"]]$read()
  rois <- h5file[["roi_numbers"]]$read()
  thresholds <- h5file[["thresholds"]]$read()

  expect_true(is.matrix(scores))
  # HDF5 may transpose the matrix; check that dimensions match in either order
  score_dims <- sort(dim(scores))
  expect_equal(score_dims, sort(c(length(rois), length(labels))))
  expect_equal(length(thresholds), length(labels))
  expect_true(all(scores >= 0 & scores <= 1))
})
