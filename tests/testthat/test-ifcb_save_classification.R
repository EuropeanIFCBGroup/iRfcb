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
  unzip(test_data_zip, exdir = temp_dir)
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
  expect_true("classifierName" %in% names(h5file))
  expect_true("class_labels_auto" %in% names(h5file))
  expect_true("class_labels_above_threshold" %in% names(h5file))
  expect_true("thresholds" %in% names(h5file))

  scores <- h5file[["output_scores"]]$read()
  labels <- h5file[["class_labels"]]$read()
  rois <- h5file[["roi_numbers"]]$read()
  thresholds <- h5file[["thresholds"]]$read()

  expect_true(is.matrix(scores))
  expect_equal(ncol(scores), length(labels))
  expect_equal(nrow(scores), length(rois))
  expect_equal(length(thresholds), length(labels))
  expect_true(all(scores >= 0 & scores <= 1))
})
