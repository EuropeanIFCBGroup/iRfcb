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
                    "n_chains", "mean_chain_length", "median_chain_length",
                    "max_chain_length") %in% colnames(res)))

  skel <- res[res$class == "Skeletonema", ]
  meso <- res[res$class == "Mesodinium", ]

  # Default single_cell_values = c(-1, 0): cells = 1 + 1 + 1 + 5 = 8
  expect_equal(skel$cell_counts, 8)
  expect_equal(skel$counts, 4)
  # n_chains and length stats only over cell_count >= 1: {1, 5}
  expect_equal(skel$n_chains, 2)
  expect_equal(skel$mean_chain_length, 3)
  expect_equal(skel$median_chain_length, 3)
  expect_equal(skel$max_chain_length, 5)

  # Mesodinium all -1: each counts as one cell, no genuine chains
  expect_equal(meso$cell_counts, 2)
  expect_equal(meso$n_chains, 0)
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
  expect_false(any(c("median_chain_length", "max_chain_length", "n_chains") %in% colnames(res)))
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
  expect_equal(res$n_chains, 2)      # {2, 4}
  expect_equal(res$max_chain_length, 4)
})
