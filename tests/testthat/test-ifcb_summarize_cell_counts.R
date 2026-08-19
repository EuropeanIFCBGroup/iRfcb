# Helper to create a unique, empty temporary directory (cleared at session end)
fresh_dir <- function() {
  d <- tempfile("chaincount-")
  dir.create(d)
  d
}

# Helper to write a minimal class .h5 file, optionally with a cell_count dataset
# and arbitrary extra datasets (named list, written verbatim).
write_test_class_h5 <- function(path, roi, classes, chain = NULL, extra = NULL) {
  f <- hdf5r::H5File$new(path, mode = "w")
  on.exit(f$close_all(), add = TRUE)
  cl <- sort(unique(classes))
  f[["class_labels"]] <- cl
  f[["roi_numbers"]] <- as.integer(roi)
  f[["output_scores"]] <- matrix(0.9, nrow = length(cl), ncol = length(roi))
  f[["classifier_name"]] <- "test_clf"
  f[["class_name_auto"]] <- classes
  f[["class_name"]] <- classes
  f[["thresholds"]] <- rep(0.5, length(cl))
  if (!is.null(chain)) {
    f[["cell_count"]] <- as.integer(chain)
  }
  for (name in names(extra)) {
    f[[name]] <- extra[[name]]
  }
  invisible(path)
}

# Helper to write a minimal automated class .mat file, optionally with a
# cell_count variable, mirroring write_test_class_h5.
write_test_class_mat <- function(path, roi, classes, chain = NULL) {
  cl <- sort(unique(classes))
  args <- list(
    con = path,
    class2useTB = cl,
    roinum = as.integer(roi),
    TBscores = matrix(0.9, nrow = length(roi), ncol = length(cl)),
    TBclass = classes,
    TBclass_above_threshold = classes,
    classifierName = "test_clf"
  )
  if (!is.null(chain)) {
    args$cell_count <- as.integer(chain)
  }
  do.call(R.matlab::writeMat, args)
  invisible(path)
}

test_that("resolve_cell_counts maps single_cell_values to 1 and passes others through", {
  expect_equal(resolve_cell_counts(c(-1, 0, 1, 5), c(-1, 0)), c(1, 1, 1, 5))
  # Removing 0 from single_cell_values keeps it verbatim
  expect_equal(resolve_cell_counts(c(-1, 0, 1, 5), c(-1)), c(1, 0, 1, 5))
  # NA chain counts stay NA
  expect_equal(resolve_cell_counts(c(NA_integer_, 2L), c(-1, 0)), c(NA, 2))
})

test_that("resolve_cell_counts warns when negative values remain after mapping", {
  # -1 not listed -> remains negative -> warning
  expect_warning(resolve_cell_counts(c(-1, 2), c(0)), "Negative cell counts")
})

test_that("ifcb_summarize_cell_counts computes abundance and chain-length stats", {
  skip_if_not_installed("hdf5r")
  dir <- fresh_dir()

  write_test_class_h5(
    file.path(dir, "D20220101T000000_IFCB001_class.h5"),
    roi = 1:6,
    classes = c("Skeletonema", "Skeletonema", "Skeletonema", "Skeletonema",
                "Mesodinium", "Mesodinium"),
    chain = c(-1, 0, 1, 5, -1, -1)
  )

  res <- ifcb_summarize_cell_counts(dir, verbose = FALSE)

  expect_s3_class(res, "data.frame")
  expect_true(all(c("sample", "classifier", "class", "counts", "cell_counts",
                    "n_counted", "mean_chain_length", "median_chain_length",
                    "max_chain_length") %in% colnames(res)))

  skel <- res[res$class == "Skeletonema", ]
  meso <- res[res$class == "Mesodinium", ]

  # Default single_cell_values = c(-1, 0): cells = 1 + 1 + 1 + 5 = 8
  expect_equal(skel$cell_counts, 8)
  expect_equal(skel$counts, 4)
  # n_counted and length stats only over cell_count >= 1: {1, 5}
  expect_equal(skel$n_counted, 2)
  expect_equal(skel$mean_chain_length, 3)
  expect_equal(skel$median_chain_length, 3)
  expect_equal(skel$max_chain_length, 5)

  # Mesodinium all -1: each counts as one cell, no genuine chains
  expect_equal(meso$cell_counts, 2)
  expect_equal(meso$n_counted, 0)
  expect_true(is.na(meso$mean_chain_length))
})

test_that("single_cell_values controls how cell_count == 0 is counted", {
  skip_if_not_installed("hdf5r")
  dir <- fresh_dir()
  write_test_class_h5(
    file.path(dir, "D20220101T000000_IFCB001_class.h5"),
    roi = 1:4,
    classes = rep("Skeletonema", 4),
    chain = c(-1, 0, 1, 5)
  )

  # Drop 0 from single_cell_values so a zero-box ROI contributes 0 cells
  res <- ifcb_summarize_cell_counts(dir, single_cell_values = c(-1),
                                     stats = character(0), verbose = FALSE)
  expect_equal(res$cell_counts, 7)  # 1 + 0 + 1 + 5
  # Only base columns when stats = character(0)
  expect_equal(colnames(res), c("sample", "classifier", "class", "counts", "cell_counts"))
})

test_that("ifcb_summarize_cell_counts selects the requested stats", {
  skip_if_not_installed("hdf5r")
  dir <- fresh_dir()
  write_test_class_h5(
    file.path(dir, "D20220101T000000_IFCB001_class.h5"),
    roi = 1:3, classes = rep("Skeletonema", 3), chain = c(1, 2, 3)
  )

  res <- ifcb_summarize_cell_counts(dir, stats = c("mean", "sd"), verbose = FALSE)
  expect_true(all(c("mean_chain_length", "sd_chain_length") %in% colnames(res)))
  expect_false(any(c("median_chain_length", "max_chain_length", "n_counted") %in% colnames(res)))
  expect_equal(res$mean_chain_length, 2)
})

test_that("ifcb_summarize_cell_counts rejects invalid stats", {
  skip_if_not_installed("hdf5r")
  dir <- fresh_dir()
  write_test_class_h5(
    file.path(dir, "D20220101T000000_IFCB001_class.h5"),
    roi = 1L, classes = "Skeletonema", chain = 1L
  )
  expect_error(ifcb_summarize_cell_counts(dir, stats = "average", verbose = FALSE),
               "Invalid value")
})

test_that("ifcb_summarize_cell_counts aborts when no file has chain-count data", {
  skip_if_not_installed("hdf5r")
  dir <- fresh_dir()
  write_test_class_h5(
    file.path(dir, "D20220101T000000_IFCB001_class.h5"),
    roi = 1:2, classes = rep("Skeletonema", 2), chain = NULL
  )
  expect_error(ifcb_summarize_cell_counts(dir, verbose = FALSE),
               "chain-count data")
})

test_that("read_class_file surfaces extra_datasets verbatim and skips missing ones", {
  skip_if_not_installed("hdf5r")
  dir <- fresh_dir()
  path <- file.path(dir, "D20220101T000000_IFCB001_class.h5")
  write_test_class_h5(
    path,
    roi = 1:3, classes = rep("Skeletonema", 3), chain = c(2, 1, 3),
    extra = list(
      cell_width_mean = c(10.5, 8.2, 12.0),       # fixed-length per-ROI
      cell_lengths = list(c(5, 6), 7, c(8, 9, 10)) # ragged per-cell (vlen)
    )
  )

  # By default, extra datasets are not read
  default <- read_class_file(path)
  expect_null(default$cell_lengths)
  expect_false(is.null(default$cell_count))

  # Requested extra datasets are returned verbatim
  res <- read_class_file(path, extra_datasets = c("cell_width_mean", "cell_lengths", "missing"))
  expect_equal(res$cell_width_mean, c(10.5, 8.2, 12.0))
  expect_type(res$cell_lengths, "list")        # ragged data as per-ROI list
  expect_equal(res$cell_lengths[[3]], c(8, 9, 10))
  expect_null(res$missing)                      # absent datasets silently skipped
})

test_that("ifcb_summarize_cell_counts reads cell_count from CSV files", {
  dir <- fresh_dir()
  csv <- data.frame(
    file_name = sprintf("D20220101T000000_IFCB001_%05d.png", 1:4),
    class_name = rep("Skeletonema", 4),
    class_name_auto = rep("Skeletonema", 4),
    score = rep(0.9, 4),
    cell_count = c(-1, 0, 2, 4)
  )
  utils::write.csv(csv, file.path(dir, "D20220101T000000_IFCB001.csv"), row.names = FALSE)

  res <- ifcb_summarize_cell_counts(dir, verbose = FALSE)
  expect_equal(res$cell_counts, 8)   # 1 + 1 + 2 + 4
  expect_equal(res$n_counted, 2)      # {2, 4}
  expect_equal(res$max_chain_length, 4)
})

test_that("ifcb_summarize_cell_counts reads cell_count from .mat files", {
  skip_if_not_installed("R.matlab")
  dir <- fresh_dir()
  write_test_class_mat(
    file.path(dir, "D20220101T000000_IFCB001_class_v1.mat"),
    roi = 1:6,
    classes = c("Skeletonema", "Skeletonema", "Skeletonema", "Skeletonema",
                "Mesodinium", "Mesodinium"),
    chain = c(-1, 0, 1, 5, -1, -1)
  )

  res <- ifcb_summarize_cell_counts(dir, verbose = FALSE)

  skel <- res[res$class == "Skeletonema", ]
  meso <- res[res$class == "Mesodinium", ]

  # Default single_cell_values = c(-1, 0): cells = 1 + 1 + 1 + 5 = 8
  expect_equal(skel$cell_counts, 8)
  expect_equal(skel$n_counted, 2)
  expect_equal(skel$mean_chain_length, 3)
  expect_equal(skel$max_chain_length, 5)
  expect_equal(meso$cell_counts, 2)
  expect_equal(meso$n_counted, 0)
})

test_that("ifcb_summarize_cell_counts gives identical results for .mat and .h5", {
  skip_if_not_installed("R.matlab")
  skip_if_not_installed("hdf5r")

  roi <- 1:6
  classes <- c("Skeletonema", "Skeletonema", "Skeletonema", "Skeletonema",
               "Mesodinium", "Mesodinium")
  chain <- c(-1, 0, 1, 5, -1, -1)

  mat_path <- file.path(fresh_dir(), "D20220101T000000_IFCB001_class_v1.mat")
  h5_path <- file.path(fresh_dir(), "D20220101T000000_IFCB001_class.h5")
  write_test_class_mat(mat_path, roi = roi, classes = classes, chain = chain)
  write_test_class_h5(h5_path, roi = roi, classes = classes, chain = chain)

  res_mat <- ifcb_summarize_cell_counts(mat_path, verbose = FALSE)
  res_h5 <- ifcb_summarize_cell_counts(h5_path, verbose = FALSE)

  # classifier field aside, the abundance and chain-length columns must match
  drop_classifier <- function(x) x[, setdiff(colnames(x), "classifier"), drop = FALSE]
  expect_equal(drop_classifier(res_mat), drop_classifier(res_h5))
})

test_that("ifcb_summarize_cell_counts aborts when .mat file has no chain data", {
  skip_if_not_installed("R.matlab")
  dir <- fresh_dir()
  write_test_class_mat(
    file.path(dir, "D20220101T000000_IFCB001_class_v1.mat"),
    roi = 1:2, classes = rep("Skeletonema", 2), chain = NULL
  )
  expect_error(ifcb_summarize_cell_counts(dir, verbose = FALSE),
               "chain-count data")
})

test_that("ifcb_summarize_cell_counts aborts when a sample resolves to two files", {
  skip_if_not_installed("R.matlab")
  skip_if_not_installed("hdf5r")
  dir <- fresh_dir()
  # Same sample in both .mat and .h5 form would otherwise double the counts
  write_test_class_mat(
    file.path(dir, "D20220101T000000_IFCB001_class_v1.mat"),
    roi = 1:3, classes = rep("Skeletonema", 3), chain = c(1, 2, 3)
  )
  write_test_class_h5(
    file.path(dir, "D20220101T000000_IFCB001_class.h5"),
    roi = 1:3, classes = rep("Skeletonema", 3), chain = c(1, 2, 3)
  )
  expect_error(ifcb_summarize_cell_counts(dir, verbose = FALSE),
               "more than one classification file")
})

test_that("ifcb_summarize_cell_counts skips manual .mat annotation files", {
  skip_if_not_installed("R.matlab")
  dir <- fresh_dir()
  # A manual annotation file (class2use_manual, no TBclass/roinum) must be
  # ignored rather than contributing a junk NA-class row.
  R.matlab::writeMat(
    file.path(dir, "D20220101T000000_IFCB001_class_v1.mat"),
    class2use_manual = c("Skeletonema", "Mesodinium"),
    classlist = matrix(c(1, 2, 1, 2), ncol = 2)
  )
  write_test_class_mat(
    file.path(dir, "D20220102T000000_IFCB001_class_v1.mat"),
    roi = 1:2, classes = rep("Skeletonema", 2), chain = c(1, 2)
  )

  res <- suppressWarnings(ifcb_summarize_cell_counts(dir, verbose = FALSE))

  # Only the automated sample survives; no NA-class row from the manual file
  expect_equal(nrow(res), 1)
  expect_equal(res$sample, "D20220102T000000_IFCB001")
  expect_false(any(is.na(res$class)))
})

# Helper writing a valid ClassiPyR .csv label file for a sample
write_label_csv <- function(path, sample, roi, classes, chain) {
  utils::write.csv(
    data.frame(
      file_name = sprintf("%s_%05d.png", sample, roi),
      class_name = classes,
      class_name_auto = classes,
      score = 0.9,
      cell_count = as.integer(chain)
    ),
    path, row.names = FALSE
  )
  invisible(path)
}

# Helper writing an IFCB-Dashboard class_scores export (pid + per-class score
# columns), which is NOT a ClassiPyR class file.
write_scores_csv <- function(path, sample, roi, classes) {
  df <- data.frame(pid = sprintf("%s_%05d", sample, roi))
  for (cl in unique(classes)) df[[cl]] <- 0.5
  utils::write.csv(df, path, row.names = FALSE)
  invisible(path)
}

test_that("read_class_file aborts on a non-class .csv naming the missing columns", {
  dir <- fresh_dir()
  path <- file.path(dir, "D20220101T000000_IFCB001_class.csv")
  write_scores_csv(path, "D20220101T000000_IFCB001", 1:3, c("Skeletonema", "Mesodinium"))

  expect_error(read_class_file(path), "not a ClassiPyR classification file")
  expect_error(read_class_file(path), "file_name")
  expect_error(read_class_file(path), "class_name")

  # An empty/unreadable .csv routes to the same clear abort, not a cryptic
  # "no lines available in input" error.
  empty <- file.path(dir, "empty.csv")
  file.create(empty)
  expect_error(read_class_file(empty), "not a ClassiPyR classification file")
})

test_that("ifcb_summarize_cell_counts aborts on an explicit non-class .csv path", {
  dir <- fresh_dir()
  bad <- file.path(dir, "D20220101T000000_IFCB001_class.csv")
  write_scores_csv(bad, "D20220101T000000_IFCB001", 1:3, "Skeletonema")

  # Explicit file path (not a folder) is not pre-filtered, so it aborts clearly
  expect_error(ifcb_summarize_cell_counts(bad, verbose = FALSE),
               "not a ClassiPyR classification file")
})

test_that("class_csv_missing_columns flags non-class and empty CSVs, passes valid ones", {
  dir <- fresh_dir()
  label <- file.path(dir, "D20220101T000000_IFCB001.csv")
  scores <- file.path(dir, "D20220101T000000_IFCB001_class.csv")
  empty <- file.path(dir, "empty.csv")
  write_label_csv(label, "D20220101T000000_IFCB001", 1:2, rep("Skeletonema", 2), c(1, 2))
  write_scores_csv(scores, "D20220101T000000_IFCB001", 1:2, "Skeletonema")
  file.create(empty)

  expect_equal(class_csv_missing_columns(label), character(0))
  expect_setequal(class_csv_missing_columns(scores), c("file_name", "class_name"))
  expect_setequal(class_csv_missing_columns(empty), c("file_name", "class_name"))
})

test_that("ifcb_summarize_cell_counts skips a dashboard scores .csv in a mixed folder", {
  sample <- "D20220101T000000_IFCB001"
  roi <- 1:4
  classes <- c("Skeletonema", "Skeletonema", "Mesodinium", "unclassified")
  chain <- c(-1, 5, -1, 0)

  # Mixed folder: valid label CSV + dashboard scores CSV for the same sample
  mixed <- fresh_dir()
  write_label_csv(file.path(mixed, paste0(sample, ".csv")), sample, roi, classes, chain)
  write_scores_csv(file.path(mixed, paste0(sample, "_class.csv")), sample, roi, classes)

  # Label-only baseline
  label_only <- fresh_dir()
  write_label_csv(file.path(label_only, paste0(sample, ".csv")), sample, roi, classes, chain)

  expect_warning(
    res_mixed <- ifcb_summarize_cell_counts(mixed, verbose = FALSE),
    "not a ClassiPyR class file"
  )
  res_label <- ifcb_summarize_cell_counts(label_only, verbose = FALSE)

  expect_equal(res_mixed, res_label)
})

test_that("ifcb_summarize_cell_counts fails clearly when only a non-class .csv is present", {
  sample <- "D20220101T000000_IFCB001"
  dir <- fresh_dir()
  write_scores_csv(file.path(dir, paste0(sample, "_class.csv")), sample, 1:3, "Skeletonema")

  # Warning names the skipped file/columns, then a clear "no files" abort (no
  # cryptic downstream failure). Warning fires even at verbose = FALSE.
  expect_warning(
    expect_error(
      ifcb_summarize_cell_counts(dir, verbose = FALSE),
      "No .* classification files found"
    ),
    "not a ClassiPyR class file"
  )
})

test_that("samples from a file without cell_count report NA, not zero cells", {
  skip_if_not_installed("hdf5r")
  dir <- fresh_dir()

  # One file carries chain counts, the other predates chain counting.
  write_test_class_h5(file.path(dir, "D20220101T000000_IFCB001_class_v1.h5"),
                      roi = 1:4, classes = rep("Skeletonema", 4),
                      chain = c(-1, 0, 2, 3))
  write_test_class_h5(file.path(dir, "D20220102T000000_IFCB001_class_v1.h5"),
                      roi = 1:5, classes = rep("Skeletonema", 5),
                      chain = NULL)

  # The mixed input is a data-integrity condition, so it warns regardless of
  # `verbose` - a scripted pipeline must not be able to silence it.
  expect_warning(
    res <- ifcb_summarize_cell_counts(dir, verbose = FALSE),
    "not contain chain-count data"
  )

  res <- res[order(res$sample), ]

  # The chain-counted sample is unaffected: 1 + 1 + 2 + 3.
  expect_equal(res$counts[1], 4L)
  expect_equal(res$cell_counts[1], 7)

  # The sample without chain counts has 5 ROIs and an unknown cell total. It
  # must not be reported as 0 cells, which would read as "taxon absent" in a
  # per-liter abundance destined for GBIF/OBIS/SHARK.
  expect_equal(res$counts[2], 5L)
  expect_true(is.na(res$cell_counts[2]))
})

test_that("a missing cell_count inside a chain-counted file warns and reports NA", {
  skip_if_not_installed("hdf5r")
  dir <- fresh_dir()

  # The file carries chain-count data, but one ROI's value is missing (a blank
  # CSV cell or HDF5 NaN in the wild). The group total used to silently become
  # NA with no diagnostic at all - the "no chain data" warning only covers
  # files with no cell_count dataset whatsoever.
  write_test_class_h5(file.path(dir, "D20220101T000000_IFCB001_class_v1.h5"),
                      roi = 1:4, classes = rep("Skeletonema", 4),
                      chain = c(2, NaN, 3, 4))

  expect_warning(
    res <- ifcb_summarize_cell_counts(dir, verbose = FALSE),
    "missing"
  )

  # The abundance is unknown, not zero, and the chain statistics still cover
  # the three measured ROIs.
  expect_true(is.na(res$cell_counts))
  expect_equal(res$counts, 4L)
  expect_equal(res$n_counted, 3L)
  expect_equal(res$mean_chain_length, 3)
})

test_that("a valid label file named {sample}_class.csv resolves to the bare sample", {
  sample <- "D20220101T000000_IFCB001"
  dir <- fresh_dir()
  write_label_csv(file.path(dir, paste0(sample, "_class.csv")), sample,
                  1:3, rep("Skeletonema", 3), c(2, 3, 4))

  res <- ifcb_summarize_cell_counts(dir, verbose = FALSE)
  # The suffix used to leak into the sample id, creating a phantom
  # "D..._IFCB001_class" sample that no HDR file could ever match.
  expect_equal(unique(res$sample), sample)
})

test_that("two valid label CSVs for one sample abort as duplicates, not phantom rows", {
  sample <- "D20220101T000000_IFCB001"
  dir <- fresh_dir()
  write_label_csv(file.path(dir, paste0(sample, ".csv")), sample,
                  1:3, rep("Skeletonema", 3), c(2, 3, 4))
  write_label_csv(file.path(dir, paste0(sample, "_class.csv")), sample,
                  1:3, rep("Skeletonema", 3), c(2, 3, 4))

  # Under the old suffix handling these read as two different samples and both
  # rows were returned; ifcb_extract_biovolumes() aborted on the same input.
  expect_error(
    ifcb_summarize_cell_counts(dir, verbose = FALSE),
    "more than one classification file"
  )
})

test_that("an hdr_folder matching no samples warns and reports NA per-liter values", {
  sample <- "D20220101T000000_IFCB001"
  dir <- fresh_dir()
  write_label_csv(file.path(dir, paste0(sample, ".csv")), sample,
                  1:3, rep("Skeletonema", 3), c(2, 3, 4))
  empty_hdr <- fresh_dir()

  # This used to abort with "Join columns in `y` must be present in the data".
  expect_warning(
    res <- ifcb_summarize_cell_counts(dir, hdr_folder = empty_hdr, verbose = FALSE),
    "match the classified samples"
  )
  expect_true(all(is.na(res$ml_analyzed)))
  expect_true(all(is.na(res$cell_counts_per_liter)))
  expect_false(all(is.na(res$cell_counts)))
})

test_that("classifier is a plain character column when reading .mat files", {
  skip_if_not_installed("R.matlab")
  dir <- fresh_dir()
  write_test_class_mat(file.path(dir, "D20220101T000000_IFCB001_class_v1.mat"),
                       roi = 1:3, classes = rep("Skeletonema", 3), chain = c(2, 3, 4))

  res <- ifcb_summarize_cell_counts(dir, verbose = FALSE)
  # read_mat() returns classifierName as a 1x1 matrix; it used to become a
  # matrix *column*, breaking bind_rows() against .h5-derived results.
  expect_false(is.matrix(res$classifier))
  expect_type(res$classifier, "character")
  expect_equal(unique(res$classifier), "test_clf")
})
