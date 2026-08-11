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

test_that("an un-evaluable check (NA) is treated as not applicable, not a failure", {
  # Legacy IFCB headers omit the post-run `roiCount` field, so `roi_count_match`
  # cannot be evaluated (NA). Such a sample must still pass on the checks that
  # do apply rather than being failed for a check that cannot run.
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

  # Drop the roiCount line to emulate the legacy header format
  hf <- file.path(work, paste0(nm, ".hdr"))
  lines <- readLines(hf)
  writeLines(lines[!grepl("^roiCount", lines, ignore.case = TRUE)], hf)

  qc <- ifcb_qc_sample(file.path(work, nm))
  expect_true(is.na(qc$hdr_roi_count))
  expect_true(is.na(qc$roi_count_match))
  # The applicable checks still hold, so the sample passes
  expect_true(qc$files_complete)
  expect_true(qc$roi_data_complete)
  expect_true(qc$runtime_consistent)
  expect_true(qc$volume_ok)
  expect_true(qc$qc_pass)
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

test_that("a directory exposes a sample missing its .adc as incomplete", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  src <- file.path(temp_dir, "test_data", "data", "D20220522T003051_IFCB134")

  nm <- "D20220522T003051_IFCB134"
  work <- tempfile()
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)
  # Copy only the .hdr and .roi (no .adc): discovery keyed solely on .adc would
  # silently drop this sample instead of reporting it as incomplete.
  for (ext in c(".hdr", ".roi")) {
    file.copy(paste0(src, ext), file.path(work, paste0(nm, ext)))
  }

  qc <- ifcb_qc_sample(work)
  expect_equal(nrow(qc), 1)
  expect_false(qc$has_adc)
  expect_false(qc$files_complete)
  expect_false(qc$qc_pass)
})

test_that("a zero-trigger sample is flagged is_empty rather than failing as unreadable", {
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
  # A sample that never triggered: empty .adc (and .roi), and a header with no
  # imaged ROIs.
  file.create(file.path(work, paste0(nm, ".adc")))
  file.create(file.path(work, paste0(nm, ".roi")))
  hf <- file.path(work, paste0(nm, ".hdr"))
  lines <- readLines(hf, warn = FALSE)
  lines <- sub("^roiCount:.*$", "roiCount: 0", lines)
  writeLines(lines, hf)

  qc <- ifcb_qc_sample(file.path(work, nm))
  expect_equal(qc$n_rois, 0)
  expect_true(qc$is_empty)            # advisory flag actually fires
  expect_true(qc$roi_count_match)     # 0 imaged == header roiCount 0

  # No volume can be computed for a sample that never triggered, so the check is
  # not applicable rather than failed. Being empty is reported by `is_empty`; it
  # must not also fail the integrity checks.
  expect_true(is.na(qc$volume_ok))
  expect_true(qc$qc_pass)
})

test_that("a zero analyzed volume fails even when the sample is empty", {
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

  # The companion of the empty-sample case above, and the other side of the
  # `volume_ok` NA rule. Here the ADC does have rows, so a volume *can* be
  # computed, but the trigger was inhibited for the whole run and the look time
  # comes out as zero. No ROI is imaged either, so the sample is empty as well.
  af <- file.path(work, paste0(nm, ".adc"))
  adc <- utils::read.csv(af, header = FALSE)
  adc[[16]] <- 0            # RoiWidth  - nothing imaged
  adc[[17]] <- 0            # RoiHeight
  # A saturated inhibit clock: small, well-behaved increments (so the rows pass
  # the reference's corrupt-row filter and the value is used as-is) that reach
  # the final run time - the trigger was inhibited for the whole run, so the
  # look time computes to exactly zero. Setting the column equal to RunTime
  # outright would not do: those steps (45 s, 670 s) fail the filter, and the
  # reference then discards the column as corrupt and falls back to the
  # header's inhibittime.
  n <- nrow(adc)
  adc[[24]] <- adc[[n, 23]] - (n - seq_len(n)) * 0.05
  utils::write.table(adc, af, sep = ",", row.names = FALSE, col.names = FALSE)

  qc <- ifcb_qc_sample(file.path(work, nm))
  expect_equal(qc$n_rois, 0)
  expect_true(qc$is_empty)
  expect_equal(qc$ml_analyzed, 0)

  # A computed zero is an answer, not a check that could not be run, so unlike
  # the NA case it must fail. Being empty does not excuse it: the instrument ran
  # and analyzed no water.
  expect_false(qc$volume_ok)
  expect_false(qc$qc_pass)
})

test_that("a non-positive syringe volume in the header falls back to the standard", {
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
  lines <- sub("^SyringeSampleVolume:.*$", "SyringeSampleVolume: 0", lines)
  writeLines(lines, hf)

  # A zero ceiling taken literally would fail every sample it appears on, so the
  # 5 mL IFCB standard is used instead and this healthy sample still passes.
  qc <- ifcb_qc_sample(file.path(work, nm))
  expect_true(qc$ml_analyzed > 0)
  expect_true(qc$volume_ok)
  expect_true(qc$qc_pass)
})

test_that("a malformed ADC width does not abort the whole survey", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  data_dir <- file.path(temp_dir, "test_data", "data")
  src <- file.path(data_dir, "D20220522T003051_IFCB134")

  work <- tempfile()
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)

  # A healthy sample alongside one whose ADC carries a non-numeric ROI width.
  good <- "D20220522T003051_IFCB134"
  bad <- "D20220522T003051_IFCB999"
  for (ext in c(".hdr", ".adc", ".roi")) {
    file.copy(paste0(src, ext), file.path(work, paste0(good, ext)))
    file.copy(paste0(src, ext), file.path(work, paste0(bad, ext)))
  }
  af <- file.path(work, paste0(bad, ".adc"))
  adc_lines <- readLines(af, warn = FALSE)
  fields <- strsplit(adc_lines[1], ",", fixed = TRUE)[[1]]
  fields[16] <- "NaN"
  adc_lines[1] <- paste(fields, collapse = ",")
  writeLines(adc_lines, af)

  # The malformed width used to make n_rois NA, which threw and took every
  # other result with it - in a function whose whole purpose is finding
  # corrupt files.
  qc <- ifcb_qc_sample(work)
  expect_equal(nrow(qc), 2L)
  expect_true(all(!is.na(qc$n_rois)))
  expect_true(qc$qc_pass[qc$sample == good])

  # Surviving the run is not enough: the damaged sample must also be reported as
  # damaged rather than quietly counted as one ROI short.
  expect_equal(qc$n_roi_malformed[qc$sample == bad], 1L)
  expect_false(qc$roi_dims_valid[qc$sample == bad])
  expect_false(qc$qc_pass[qc$sample == bad])
  expect_equal(qc$n_roi_malformed[qc$sample == good], 0L)
  expect_true(qc$roi_dims_valid[qc$sample == good])
})

test_that("a blank ROI dimension fails QC instead of masquerading as an empty sample", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  src <- file.path(temp_dir, "test_data", "data", "D20220522T003051_IFCB134")

  # `read_adc_columns()` is a plain `read.csv()`, so a blank, whitespace or NaN
  # width is accepted as a numeric NA rather than raising. Every such row drops
  # out of `imaged`, collapsing `n_rois` to 0 - which, on a legacy header with
  # no `roiCount` to compare against, used to be indistinguishable from a sample
  # that never triggered and so passed QC outright.
  for (token in c("", " ", "NaN", "NA")) {
    nm <- "D20220522T003051_IFCB134"
    work <- tempfile()
    dir.create(work)
    on.exit(unlink(work, recursive = TRUE), add = TRUE)
    for (ext in c(".hdr", ".adc", ".roi")) {
      file.copy(paste0(src, ext), file.path(work, paste0(nm, ext)))
    }

    af <- file.path(work, paste0(nm, ".adc"))
    adc_lines <- vapply(readLines(af, warn = FALSE), function(line) {
      fields <- strsplit(line, ",", fixed = TRUE)[[1]]
      fields[16] <- token
      paste(fields, collapse = ",")
    }, character(1), USE.NAMES = FALSE)
    writeLines(adc_lines, af)

    # Strip the post-run roiCount so `roi_count_match` cannot rescue the check.
    hf <- file.path(work, paste0(nm, ".hdr"))
    hdr_lines <- readLines(hf, warn = FALSE)
    writeLines(hdr_lines[!grepl("^roiCount", hdr_lines, ignore.case = TRUE)], hf)

    qc <- ifcb_qc_sample(file.path(work, nm))
    expect_true(is.na(qc$roi_count_match), info = token)   # the legacy-header gap
    expect_equal(qc$n_rois, 0)                             # looks empty...
    expect_true(qc$is_empty, info = token)
    expect_true(qc$n_roi_malformed > 0, info = token)      # ...but is reported
    expect_false(qc$roi_dims_valid, info = token)
    expect_false(qc$qc_pass, info = token)
  }
})

test_that("an unreadable start byte on an imaged ROI is caught, not averaged away", {
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

  # Blank the start byte (column 18) of the first imaged ROI, leaving its width
  # and height intact and a second imaged ROI untouched. `roi_bytes_expected`
  # takes `max(..., na.rm = TRUE)` over the survivors, so it still returns a
  # plausible extent and `roi_data_complete` stays TRUE - the damage is averaged
  # away rather than detected. Only the malformed-row count catches it.
  af <- file.path(work, paste0(nm, ".adc"))
  adc <- read_adc_columns(af)
  rc <- suppressWarnings(adc_get_roi_columns(adc))
  target <- which(rc$x > 0)[1]

  adc_lines <- readLines(af, warn = FALSE)
  fields <- strsplit(adc_lines[target], ",", fixed = TRUE)[[1]]
  fields[18] <- ""
  adc_lines[target] <- paste(fields, collapse = ",")
  writeLines(adc_lines, af)

  qc <- suppressWarnings(ifcb_qc_sample(file.path(work, nm)))
  expect_true(qc$roi_data_complete)      # the check that cannot see it
  expect_equal(qc$n_roi_malformed, 1L)
  expect_false(qc$roi_dims_valid)
  expect_false(qc$qc_pass)
})

test_that("an unreadable ADC leaves roi_dims_valid NA and still fails on volume", {
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

  # An .adc holding nothing but line terminators - a write that opened the file
  # and got no further - is non-empty, so it does not take the zero-length
  # shortcut, but `read.csv()` cannot parse it either. Nothing about the ROI
  # dimensions is then known, which is a different defect from a
  # parseable-but-blank dimension and must not be reported as zero malformed
  # rows.
  af <- file.path(work, paste0(nm, ".adc"))
  writeBin(charToRaw("\n\n\n"), af)

  qc <- ifcb_qc_sample(file.path(work, nm))
  expect_true(is.na(qc$n_roi_malformed))
  expect_true(is.na(qc$roi_dims_valid))
  expect_false(qc$qc_pass)   # volume_ok still catches it
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

test_that("a header run time shorter than the ADC fails runtime_consistent and qc_pass", {
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
  # Truncate/corrupt the header runTime so it is shorter than the run time the
  # ADC recorded at its last trigger (physically impossible -> inconsistent).
  hf <- file.path(work, paste0(nm, ".hdr"))
  lines <- readLines(hf, warn = FALSE)
  lines <- sub("^runTime:.*$", "runTime: 10", lines)
  writeLines(lines, hf)

  qc <- ifcb_qc_sample(file.path(work, nm))
  expect_false(qc$runtime_consistent)
  expect_false(qc$qc_pass)
})

test_that("a run continuing past the last trigger is not flagged inconsistent", {
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
  # A sparse sample: the last imaged trigger fires well before the run ends.
  # The header (total) run time legitimately exceeds the ADC's last trigger,
  # which must NOT be treated as a corruption.
  af <- file.path(work, paste0(nm, ".adc"))
  adc <- utils::read.csv(af, header = FALSE)
  adc[nrow(adc), 23] <- adc[nrow(adc), 23] / 2   # last trigger at ~half the run
  utils::write.table(adc, af, sep = ",", row.names = FALSE, col.names = FALSE)

  qc <- ifcb_qc_sample(file.path(work, nm))
  expect_true(qc$runtime_consistent)
  expect_true(qc$qc_pass)
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

test_that("an ADC with too few columns yields NA checks instead of aborting the survey", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  data_dir <- file.path(temp_dir, "test_data", "data")
  src <- file.path(data_dir, "D20220522T003051_IFCB134")

  work <- tempfile()
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)

  good <- "D20220522T003051_IFCB134"
  bad <- "D20220522T003051_IFCB999"
  for (ext in c(".hdr", ".adc", ".roi")) {
    file.copy(paste0(src, ext), file.path(work, paste0(good, ext)))
    file.copy(paste0(src, ext), file.path(work, paste0(bad, ext)))
  }
  # A structurally broken ADC: parses as a data frame, but with far fewer
  # columns than any ADC format holds. Indexing the ROI columns used to throw
  # `subscript out of bounds`, taking every other sample's row with it.
  writeLines(c("1,2,3", "4,5,6"), file.path(work, paste0(bad, ".adc")))

  # Two distinct diagnostics for the same broken file: the volume path reports
  # the absent run/inhibit clocks, the ROI path reports the missing dimensions.
  expect_warning(
    expect_warning(qc <- ifcb_qc_sample(work), "run/inhibit"),
    "ROI columns"
  )

  expect_equal(nrow(qc), 2L)
  expect_true(qc$qc_pass[qc$sample == good])
  bad_row <- qc[qc$sample == bad, ]
  expect_true(is.na(bad_row$n_rois))
  expect_true(is.na(bad_row$roi_dims_valid))
  expect_true(is.na(bad_row$roi_count_match))
})

test_that("a header ADCFileFormat without a ROI height column does not abort the survey", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  data_dir <- file.path(temp_dir, "test_data", "data")
  src <- file.path(data_dir, "D20220522T003051_IFCB134")

  work <- tempfile()
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)

  good <- "D20220522T003051_IFCB134"
  bad <- "D20220522T003051_IFCB999"
  for (ext in c(".hdr", ".adc", ".roi")) {
    file.copy(paste0(src, ext), file.path(work, paste0(good, ext)))
    file.copy(paste0(src, ext), file.path(work, paste0(bad, ext)))
  }
  # Rename the RoiHeight column in the header's ADC column listing. Resolving
  # the ROI columns by name then used to throw instead of reporting NA.
  hf <- file.path(work, paste0(bad, ".hdr"))
  hdr_lines <- readLines(hf, warn = FALSE)
  hdr_lines <- gsub("ROIheight", "SomethingElse", hdr_lines, ignore.case = TRUE)
  writeLines(hdr_lines, hf)

  qc <- suppressWarnings(ifcb_qc_sample(work))
  expect_equal(nrow(qc), 2L)
  expect_true(qc$qc_pass[qc$sample == good])
})

test_that("a header with a second runtime-like key yields one row, not two recycled ones", {
  temp_dir <- setup_mock_directory()
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  data_dir <- file.path(temp_dir, "test_data", "data")
  src <- file.path(data_dir, "D20220522T003051_IFCB134")

  work <- tempfile()
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE), add = TRUE)

  sample <- "D20220522T003051_IFCB134"
  for (ext in c(".hdr", ".adc", ".roi")) {
    file.copy(paste0(src, ext), file.path(work, paste0(sample, ext)))
  }
  # ifcb_get_runtime() used to grep the substring "runtime:", so an extra key
  # such as AdcRunTime: matched too and returned length-2 values, which
  # tibble() recycled into a duplicated, failing row for this sample. The
  # anchored match ignores the extra key, as MATLAB's strmatch() does, so the
  # sample parses cleanly.
  hf <- file.path(work, paste0(sample, ".hdr"))
  cat("AdcRunTime: 5\n", file = hf, append = TRUE)

  qc <- ifcb_qc_sample(work)
  expect_equal(nrow(qc), 1L)
  expect_false(is.na(qc$looktime_s))
  expect_true(qc$qc_pass)
})
