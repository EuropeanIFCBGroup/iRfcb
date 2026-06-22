# Tests for ifcb_qc_sample() and its helpers. These use the bundled raw test
# triplets (test_data.zip) and require no Python.

# ---- resolve_sample_paths() -------------------------------------------------

test_that("resolve_sample_paths discovers samples from a directory", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  data_dir <- file.path(temp_dir, "test_data", "data")

  bases <- resolve_sample_paths(data_dir)
  expect_true(length(bases) >= 1)
  expect_true(all(file.exists(paste0(bases, ".adc"))))
  expect_false(any(grepl("\\.(hdr|adc|roi)$", bases)))
})

test_that("resolve_sample_paths strips extensions and resolves names via data_folder", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  data_dir <- file.path(temp_dir, "test_data", "data")

  # extension stripping (no data_folder)
  expect_equal(
    resolve_sample_paths(file.path(data_dir, "D20220522T003051_IFCB134.roi")),
    file.path(data_dir, "D20220522T003051_IFCB134")
  )

  # bare-name resolution against data_folder
  bases <- resolve_sample_paths("D20220522T003051_IFCB134", data_folder = data_dir)
  expect_equal(basename(bases), "D20220522T003051_IFCB134")
  expect_true(file.exists(paste0(bases, ".adc")))
})

# ---- ifcb_qc_sample() integration ------------------------------------------

test_that("ifcb_qc_sample returns one tidy row per sample with the expected columns", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  data_dir <- file.path(temp_dir, "test_data", "data")

  qc <- ifcb_qc_sample(data_dir)

  expect_s3_class(qc, "tbl_df")
  expect_true(all(c("sample", "files_complete", "roi_count_match",
                    "roi_data_complete", "volume_ok", "is_bead_run",
                    "is_empty", "qc_pass") %in% names(qc)))
  expect_equal(nrow(qc), length(unique(qc$sample)))
})

test_that("ROI count consistency holds (n_rois == hdr roiCount)", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  qc <- ifcb_qc_sample(file.path(temp_dir, "test_data", "data"))

  with_counts <- qc[!is.na(qc$n_rois) & !is.na(qc$hdr_roi_count), ]
  expect_true(all(with_counts$roi_count_match))
})

test_that("a complete, consistent triplet passes QC", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  # D20220522T003051 ships as a full hdr/adc/roi triplet
  qc <- ifcb_qc_sample(file.path(temp_dir, "test_data", "data",
                                 "D20220522T003051_IFCB134"))
  expect_true(qc$files_complete)
  expect_true(qc$roi_data_complete)
  expect_true(qc$qc_pass)
})

test_that("a sample missing its .roi fails QC as incomplete", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  # D20220522T000439 ships without a .roi file
  qc <- ifcb_qc_sample(file.path(temp_dir, "test_data", "data",
                                 "D20220522T000439_IFCB134"))
  expect_false(qc$has_roi)
  expect_false(qc$files_complete)
  expect_false(qc$qc_pass)
})

test_that("a truncated .roi is flagged as incomplete", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  src <- file.path(temp_dir, "test_data", "data", "D20220522T003051_IFCB134")

  # Keep the real IFCB sample name (ifcb_read_hdr_data validates the format)
  nm <- "D20220522T003051_IFCB134"
  work <- tempfile()
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  for (ext in c(".hdr", ".adc", ".roi")) {
    file.copy(paste0(src, ext), file.path(work, paste0(nm, ext)))
  }
  rf <- file.path(work, paste0(nm, ".roi"))
  bytes <- readBin(rf, "raw", n = file.size(rf))
  writeBin(bytes[seq_len(length(bytes) %/% 2)], rf)  # truncate to half

  qc <- ifcb_qc_sample(file.path(work, nm))
  expect_lt(qc$roi_bytes, qc$roi_bytes_expected)
  expect_false(qc$roi_data_complete)
  expect_false(qc$qc_pass)
})

test_that("volume ceiling is derived from the header syringe volume", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  sample <- file.path(temp_dir, "test_data", "data", "D20220522T003051_IFCB134")

  qc <- ifcb_qc_sample(sample)
  expect_equal(qc$syringe_ml, 5)          # SyringeSampleVolume from the header
  expect_true(qc$ml_analyzed <= 5)
  expect_true(qc$volume_ok)

  # An unrealistically low fixed ceiling flags the volume and fails qc_pass
  qc_low <- ifcb_qc_sample(sample, max_ml = 1)
  expect_false(qc_low$volume_ok)
  expect_false(qc_low$qc_pass)
})

test_that("max_ml and volume_tolerance are validated", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  sample <- file.path(temp_dir, "test_data", "data", "D20220522T003051_IFCB134")
  expect_error(ifcb_qc_sample(sample, max_ml = 0), "max_ml")
  expect_error(ifcb_qc_sample(sample, max_ml = c(5, 6)), "max_ml")
  expect_error(ifcb_qc_sample(sample, volume_tolerance = -0.1), "volume_tolerance")
})

test_that("runtime_consistent passes when header and ADC agree", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  qc <- ifcb_qc_sample(file.path(temp_dir, "test_data", "data",
                                 "D20220522T003051_IFCB134"))
  expect_true(qc$runtime_consistent)
  expect_true(qc$qc_pass)
})

test_that("a header/ADC run time mismatch fails runtime_consistent and qc_pass", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  src <- file.path(temp_dir, "test_data", "data", "D20220522T003051_IFCB134")

  nm <- "D20220522T003051_IFCB134"
  work <- tempfile()
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  for (ext in c(".hdr", ".adc", ".roi")) {
    file.copy(paste0(src, ext), file.path(work, paste0(nm, ext)))
  }
  # Corrupt the header runTime so it disagrees with the ADC
  hf <- file.path(work, paste0(nm, ".hdr"))
  lines <- readLines(hf, warn = FALSE)
  lines <- sub("^runTime:.*$", "runTime: 99999", lines)
  writeLines(lines, hf)

  qc <- ifcb_qc_sample(file.path(work, nm))
  expect_false(qc$runtime_consistent)
  expect_false(qc$qc_pass)
})

test_that("runtime_tolerance is validated", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  sample <- file.path(temp_dir, "test_data", "data", "D20220522T003051_IFCB134")
  expect_error(ifcb_qc_sample(sample, runtime_tolerance = -0.01), "runtime_tolerance")
})

test_that("roi_oversized flags .roi files exceeding max_roi_mb", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  sample <- file.path(temp_dir, "test_data", "data", "D20220522T003051_IFCB134")
  roi_mb <- file.size(paste0(sample, ".roi")) / 1024^2

  # disabled by default
  expect_true(is.na(ifcb_qc_sample(sample)$roi_oversized))

  # below threshold -> not oversized
  expect_false(ifcb_qc_sample(sample, max_roi_mb = roi_mb * 2)$roi_oversized)

  # above threshold -> oversized, but advisory (qc_pass unaffected)
  qc <- ifcb_qc_sample(sample, max_roi_mb = roi_mb / 2)
  expect_true(qc$roi_oversized)
  expect_true(qc$qc_pass)
})

test_that("max_roi_mb is validated", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  sample <- file.path(temp_dir, "test_data", "data", "D20220522T003051_IFCB134")
  expect_error(ifcb_qc_sample(sample, max_roi_mb = -5), "max_roi_mb")
  expect_error(ifcb_qc_sample(sample, max_roi_mb = c(1, 2)), "max_roi_mb")
})

test_that("humidity and temperature thresholds flag exceedances", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  sample <- file.path(temp_dir, "test_data", "data", "D20220522T003051_IFCB134")

  # measured values are always reported; flags are NA when no threshold given
  qc0 <- ifcb_qc_sample(sample)
  expect_true(is.numeric(qc0$humidity) && !is.na(qc0$humidity))
  expect_true(is.numeric(qc0$temperature) && !is.na(qc0$temperature))
  expect_true(is.na(qc0$humidity_high))
  expect_true(is.na(qc0$temperature_high))

  # low thresholds -> flagged; high thresholds -> not flagged
  qc_hi <- ifcb_qc_sample(sample, max_humidity = qc0$humidity - 1,
                          max_temperature = qc0$temperature - 1)
  expect_true(qc_hi$humidity_high)
  expect_true(qc_hi$temperature_high)

  qc_lo <- ifcb_qc_sample(sample, max_humidity = qc0$humidity + 1,
                          max_temperature = qc0$temperature + 1)
  expect_false(qc_lo$humidity_high)
  expect_false(qc_lo$temperature_high)

  # advisory only: qc_pass is unaffected
  expect_equal(qc_hi$qc_pass, qc0$qc_pass)
})

test_that("max_humidity and max_temperature are validated", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  sample <- file.path(temp_dir, "test_data", "data", "D20220522T003051_IFCB134")
  expect_error(ifcb_qc_sample(sample, max_humidity = c(50, 60)), "max_humidity")
  expect_error(ifcb_qc_sample(sample, max_temperature = "hot"), "max_temperature")
})

test_that("bead runs are flagged via the header runBeads field", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  src <- file.path(temp_dir, "test_data", "data", "D20220522T003051_IFCB134")

  nm <- "D20220522T003051_IFCB134"
  work <- tempfile()
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  for (ext in c(".hdr", ".adc", ".roi")) {
    file.copy(paste0(src, ext), file.path(work, paste0(nm, ext)))
  }
  hf <- file.path(work, paste0(nm, ".hdr"))
  lines <- readLines(hf, warn = FALSE)
  lines <- sub("^runBeads:.*$", "runBeads: True", lines)
  writeLines(lines, hf)

  qc <- ifcb_qc_sample(file.path(work, nm))
  expect_true(qc$is_bead_run)
  # a bead run is still a valid, complete sample: integrity QC may still pass
  expect_true(qc$files_complete)
})
