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
                          "TBclass_above_adhocthresh"),
               ignore.order = TRUE)

  expect_true(is.character(result$classifierName))
  expect_true(is.character(result$class2useTB))
  expect_true(is.numeric(result$roinum))
  expect_true(is.matrix(result$TBscores))
  expect_true(is.character(result$TBclass))
  expect_true(is.character(result$TBclass_above_threshold))
  expect_null(result$TBclass_above_adhocthresh)
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

# ── .csv tests ────────────────────────────────────────────────────────────────

test_that("read_class_file reads .csv and returns expected fields", {
  result <- iRfcb:::read_class_file(csv_file)

  expect_type(result, "list")
  expect_named(result, c("classifierName", "class2useTB", "roinum", "TBscores",
                          "TBclass", "TBclass_above_threshold",
                          "TBclass_above_adhocthresh"),
               ignore.order = TRUE)

  expect_true(is.character(result$class2useTB))
  expect_true(is.numeric(result$roinum))
  expect_true(is.matrix(result$TBscores))
  expect_true(is.character(result$TBclass))
  expect_true(is.character(result$TBclass_above_threshold))
  expect_null(result$TBclass_above_adhocthresh)
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
