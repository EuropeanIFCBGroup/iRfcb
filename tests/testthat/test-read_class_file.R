# ── Setup: extract test data once ──────────────────────────────────────────────

test_data_zip <- test_path("test_data/test_data.zip")
temp_dir <- file.path(tempdir(), "read_class_file_tests")
utils::unzip(test_data_zip, exdir = temp_dir)

mat_file <- file.path(temp_dir, "test_data", "class", "class2022_v1",
                      "D20220522T003051_IFCB134_class_v1.mat")
h5_file  <- file.path(temp_dir, "test_data", "class", "class2022_h5",
                      "D20220522T003051_IFCB134_class.h5")
csv_file <- file.path(temp_dir, "test_data", "class", "class2022_csv",
                      "D20220522T003051_IFCB134.csv")

# Helper to write a small class .h5 file with 3 ROIs and 2 classes. `drop` leaves
# datasets out, `legacy` uses the GPU-format dataset names, and `n_roi_numbers`
# lets the ROI numbers disagree in length with the other per-ROI datasets.
write_class_h5 <- function(path, drop = character(0), legacy = FALSE, n_roi_numbers = 3) {
  datasets <- list(
    class_labels = c("ClassA", "ClassB"),
    roi_numbers = seq_len(n_roi_numbers),
    output_scores = matrix(c(0.9, 0.1, 0.2, 0.8, 0.6, 0.4), nrow = 2),
    classifier_name = "test_clf",
    class_name_auto = c("ClassA", "ClassB", "ClassA"),
    class_name = c("ClassA", "ClassB", "unclassified"),
    thresholds = c(0.5, 0.7)
  )
  if (legacy) {
    names(datasets)[match(c("classifier_name", "class_name_auto", "class_name"), names(datasets))] <-
      c("classifierName", "class_labels_auto", "class_labels_above_threshold")
  }
  f <- hdf5r::H5File$new(path, mode = "w")
  on.exit(f$close_all(), add = TRUE)
  for (name in setdiff(names(datasets), drop)) {
    f[[name]] <- datasets[[name]]
  }
  invisible(path)
}

# ── .mat tests ────────────────────────────────────────────────────────────────

test_that("read_class_file reads .mat and returns expected fields", {
  result <- iRfcb:::read_class_file(mat_file)

  expect_type(result, "list")
  expect_named(result, c("roinum", "TBclass", "TBscores", "TBclass_above_threshold",
                          "class2useTB", "classifierName"),
               ignore.order = TRUE)

  expect_true(is.numeric(result$roinum))
  expect_true(is.matrix(result$TBscores))
  expect_true(is.character(result$class2useTB))
  expect_true(is.character(result$TBclass))
  expect_true(is.character(result$TBclass_above_threshold))
  expect_true(is.character(result$classifierName))
})

test_that("read_class_file .mat has consistent dimensions", {
  result <- iRfcb:::read_class_file(mat_file)

  n_rois <- length(as.integer(result$roinum))
  n_classes <- length(result$class2useTB)

  expect_equal(nrow(result$TBscores), n_rois)
  expect_equal(length(result$TBclass), n_rois)
  expect_equal(length(result$TBclass_above_threshold), n_rois)
})

# ── .h5 tests ─────────────────────────────────────────────────────────────────

test_that("read_class_file reads .h5 and returns expected fields", {
  skip_if_not_installed("hdf5r")

  result <- iRfcb:::read_class_file(h5_file)

  expect_type(result, "list")
  expect_named(result, c("classifierName", "class2useTB", "roinum", "TBscores",
                          "TBclass", "TBclass_above_threshold",
                          "TBclass_above_adhocthresh", "cell_count"),
               ignore.order = TRUE)

  expect_true(is.character(result$classifierName))
  expect_true(is.character(result$class2useTB))
  expect_true(is.numeric(result$roinum))
  expect_true(is.matrix(result$TBscores))
  expect_true(is.character(result$TBclass))
  expect_true(is.character(result$TBclass_above_threshold))
  expect_null(result$TBclass_above_adhocthresh)
  expect_null(result$cell_count)
})

test_that("read_class_file .h5 has consistent dimensions", {
  skip_if_not_installed("hdf5r")

  result <- iRfcb:::read_class_file(h5_file)

  n_rois <- length(result$roinum)
  n_classes <- length(result$class2useTB)

  expect_equal(nrow(result$TBscores), n_rois)
  expect_equal(ncol(result$TBscores), n_classes)
  expect_equal(length(result$TBclass), n_rois)
  expect_equal(length(result$TBclass_above_threshold), n_rois)
})

test_that("read_class_file .h5 scores are in valid range", {
  skip_if_not_installed("hdf5r")

  result <- iRfcb:::read_class_file(h5_file)

  expect_true(all(result$TBscores >= 0 & result$TBscores <= 1))
})

test_that("read_class_file reads .h5 files with legacy GPU-format dataset names", {
  skip_if_not_installed("hdf5r")
  path <- write_class_h5(tempfile(fileext = ".h5"), legacy = TRUE)

  result <- iRfcb:::read_class_file(path)

  expect_equal(result$classifierName, "test_clf")
  expect_equal(result$TBclass, c("ClassA", "ClassB", "ClassA"))
  expect_equal(result$TBclass_above_threshold, c("ClassA", "ClassB", "unclassified"))
  expect_equal(dim(result$TBscores), c(3L, 2L))
})

test_that("read_class_file keeps .h5 scores as ROIs x classes when a dimension is 1", {
  skip_if_not_installed("hdf5r")
  write_scores <- function(n_rois, n_classes) {
    path <- tempfile(fileext = ".h5")
    labels <- paste0("Class", seq_len(n_classes))
    f <- hdf5r::H5File$new(path, mode = "w")
    f[["class_labels"]] <- labels
    f[["roi_numbers"]] <- seq_len(n_rois)
    f[["output_scores"]] <- matrix(0.5, nrow = n_classes, ncol = n_rois)
    f[["class_name_auto"]] <- rep(labels[1], n_rois)
    f[["class_name"]] <- rep(labels[1], n_rois)
    f$close_all()
    path
  }

  # hdf5r drops length-1 dimensions on read, which used to transpose the
  # scores of a single-class file
  expect_equal(dim(iRfcb:::read_class_file(write_scores(3, 1))$TBscores), c(3L, 1L))
  expect_equal(dim(iRfcb:::read_class_file(write_scores(1, 2))$TBscores), c(1L, 2L))
  expect_equal(dim(iRfcb:::read_class_file(write_scores(1, 1))$TBscores), c(1L, 1L))
})

test_that("read_class_file names an .h5 file that holds no datasets", {
  skip_if_not_installed("hdf5r")
  # What an interrupted classification run leaves behind: a valid HDF5 file
  # that was created but never written to
  path <- tempfile(fileext = ".h5")
  f <- hdf5r::H5File$new(path, mode = "w")
  f$close_all()

  expect_error(iRfcb:::read_class_file(path), basename(path), fixed = TRUE)
  expect_error(iRfcb:::read_class_file(path), "contains no datasets")
})

test_that("read_class_file names an .h5 file missing a required dataset", {
  skip_if_not_installed("hdf5r")
  path <- write_class_h5(tempfile(fileext = ".h5"), drop = "class_name")

  expect_error(iRfcb:::read_class_file(path), basename(path), fixed = TRUE)
  expect_error(iRfcb:::read_class_file(path), "class_name or class_labels_above_threshold")
})

test_that("read_class_file names an .h5 file that is empty or truncated", {
  skip_if_not_installed("hdf5r")
  zero_bytes <- tempfile(fileext = ".h5")
  file.create(zero_bytes)
  truncated <- tempfile(fileext = ".h5")
  bytes <- readBin(h5_file, "raw", file.size(h5_file))
  writeBin(bytes[seq_len(length(bytes) %/% 2)], truncated)

  for (path in c(zero_bytes, truncated)) {
    expect_error(iRfcb:::read_class_file(path), basename(path), fixed = TRUE)
    expect_error(iRfcb:::read_class_file(path), "not a readable HDF5 file")
  }
})

test_that("read_class_file rejects .h5 datasets of inconsistent length", {
  skip_if_not_installed("hdf5r")
  path <- write_class_h5(tempfile(fileext = ".h5"), n_roi_numbers = 2)

  expect_error(iRfcb:::read_class_file(path), basename(path), fixed = TRUE)
  expect_error(iRfcb:::read_class_file(path), "inconsistent dataset dimensions")
})

test_that("read_class_file releases the .h5 file after reading it", {
  skip_if_not_installed("hdf5r")
  complete <- write_class_h5(tempfile(fileext = ".h5"))
  incomplete <- write_class_h5(tempfile(fileext = ".h5"), drop = "class_name")

  iRfcb:::read_class_file(complete, extra_datasets = "thresholds")
  try(iRfcb:::read_class_file(incomplete), silent = TRUE)

  # HDF5 refuses to reopen a file for writing while any handle on it is still
  # open, so this fails if reading left a dataset or the file itself open
  for (path in c(complete, incomplete)) {
    expect_no_error({
      f <- hdf5r::H5File$new(path, mode = "r+")
      f$close_all()
    })
  }
})

# ── .csv tests ────────────────────────────────────────────────────────────────

test_that("read_class_file reads .csv and returns expected fields", {
  result <- iRfcb:::read_class_file(csv_file)

  expect_type(result, "list")
  expect_named(result, c("classifierName", "class2useTB", "roinum", "TBscores",
                          "TBclass", "TBclass_above_threshold",
                          "TBclass_above_adhocthresh", "cell_count"),
               ignore.order = TRUE)

  expect_true(is.character(result$class2useTB))
  expect_true(is.numeric(result$roinum))
  expect_true(is.matrix(result$TBscores))
  expect_true(is.character(result$TBclass))
  expect_true(is.character(result$TBclass_above_threshold))
  expect_null(result$TBclass_above_adhocthresh)
  expect_null(result$cell_count)
  expect_true(is.na(result$classifierName))
})

test_that("read_class_file .csv has consistent dimensions", {
  result <- iRfcb:::read_class_file(csv_file)

  n_rois <- length(result$roinum)
  n_classes <- length(result$class2useTB)

  expect_equal(nrow(result$TBscores), n_rois)
  expect_equal(ncol(result$TBscores), n_classes)
  expect_equal(length(result$TBclass), n_rois)
  expect_equal(length(result$TBclass_above_threshold), n_rois)
})

test_that("read_class_file .csv extracts ROI numbers from file_name", {
  result <- iRfcb:::read_class_file(csv_file)

  expect_equal(result$roinum, c(2L, 3L))
})

test_that("read_class_file .csv builds score matrix from winning scores", {
  result <- iRfcb:::read_class_file(csv_file)

  # Each row should have exactly one non-zero score (the winning score)
  row_sums <- rowSums(result$TBscores > 0)
  expect_true(all(row_sums == 1))
})

# ── Cross-format consistency ──────────────────────────────────────────────────

test_that("read_class_file returns same ROI numbers across all formats", {
  skip_if_not_installed("hdf5r")

  mat_result <- iRfcb:::read_class_file(mat_file)
  h5_result  <- iRfcb:::read_class_file(h5_file)
  csv_result <- iRfcb:::read_class_file(csv_file)

  mat_rois <- as.integer(mat_result$roinum)
  h5_rois  <- as.integer(h5_result$roinum)
  csv_rois <- as.integer(csv_result$roinum)

  expect_equal(h5_rois, mat_rois)
  expect_equal(csv_rois, mat_rois)
})

test_that("read_class_file returns same winning classes across all formats", {
  skip_if_not_installed("hdf5r")

  mat_result <- iRfcb:::read_class_file(mat_file)
  h5_result  <- iRfcb:::read_class_file(h5_file)
  csv_result <- iRfcb:::read_class_file(csv_file)

  expect_equal(h5_result$TBclass, mat_result$TBclass)
  expect_equal(csv_result$TBclass, mat_result$TBclass)
})

test_that("read_class_file returns same threshold classes across all formats", {
  skip_if_not_installed("hdf5r")

  mat_result <- iRfcb:::read_class_file(mat_file)
  h5_result  <- iRfcb:::read_class_file(h5_file)
  csv_result <- iRfcb:::read_class_file(csv_file)

  expect_equal(h5_result$TBclass_above_threshold, mat_result$TBclass_above_threshold)
  expect_equal(csv_result$TBclass_above_threshold, mat_result$TBclass_above_threshold)
})

test_that("read_class_file returns same score matrix across .mat and .h5", {
  skip_if_not_installed("hdf5r")

  mat_result <- iRfcb:::read_class_file(mat_file)
  h5_result  <- iRfcb:::read_class_file(h5_file)

  expect_equal(h5_result$TBscores, mat_result$TBscores, tolerance = 1e-10)
})
