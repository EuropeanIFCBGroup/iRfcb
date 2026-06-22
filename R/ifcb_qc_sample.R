utils::globalVariables(c("has_hdr", "has_adc", "has_roi", "n_rois", "hdr_roi_count",
                         "roi_bytes", "roi_bytes_expected", "ml_analyzed",
                         "files_complete", "roi_count_match", "roi_data_complete",
                         "runtime_consistent", "volume_ok"))

#' Quality-control a raw IFCB sample (hdr/adc/roi triplet)
#'
#' Validates the integrity and self-consistency of one or more raw IFCB samples
#' and returns a tidy tibble of QC metrics and flags, one row per sample. Each
#' sample is expected to consist of the standard IFCB file triplet sharing a
#' base name: a header (`.hdr`), an ADC table (`.adc`), and the raw image data
#' (`.roi`).
#'
#' @details
#' The checks build directly on the package's existing readers
#' ([ifcb_read_hdr_data()], `read_adc_columns()`, [ifcb_volume_analyzed()])
#' cover four areas:
#'
#' \describe{
#'   \item{Triplet completeness}{Whether all of `.hdr`, `.adc`, and `.roi` are
#'     present (`files_complete`).}
#'   \item{ROI count consistency}{The number of imaged ROIs in the ADC (rows
#'     with a non-zero ROI width) must equal the header's `roiCount`
#'     (`roi_count_match`). Note that the ADC row count is **not** compared to
#'     `triggerCount`: depending on the ADC format a single trigger may yield
#'     several ROIs, so `triggerCount` is reported but not used as a hard
#'     check.}
#'   \item{ROI data completeness}{The `.roi` file must be at least as large as
#'     the last image's end offset (`max(StartByte + width * height)`) computed
#'     from the ADC. A smaller file indicates a truncated or aborted transfer
#'     (`roi_data_complete`).}
#'   \item{Run time consistency}{The run time recorded in the header must agree
#'     (within `runtime_tolerance`) with the run time in the ADC. A mismatch
#'     points to corrupted or mismatched metadata (`runtime_consistent`).}
#'     \item{Flow / volume sanity}{The analyzed volume from
#'     [ifcb_volume_analyzed()] must be positive and not exceed the syringe
#'     sample volume (`volume_ok`). The ceiling is taken from the header's
#'     `SyringeSampleVolume` (reported as `syringe_ml`, e.g. 5 mL for a standard
#'     IFCB), plus `volume_tolerance`, since the analyzed volume can never
#'     physically exceed the drawn syringe volume. A fixed ceiling can be forced
#'     with `max_ml`.}
#' }
#'
#' Further advisory flags are reported but do **not** affect `qc_pass`, as they
#' describe valid samples that a user may nonetheless wish to exclude:
#' `is_bead_run` (a bead/calibration run, detected from the header's `runBeads`
#' field or a `sampleType` containing "bead"), `is_empty` (no imaged ROIs),
#' `roi_oversized` (the `.roi` file exceeds `max_roi_mb`, useful for catching
#' overloaded or anomalous runs), and `humidity_high` / `temperature_high` (the
#' header's recorded `humidity` / `temperature` exceed `max_humidity` /
#' `max_temperature`, flagging possible condensation or overheating). The latter
#' three are only evaluated when their threshold is supplied; otherwise they are
#' `NA`. The measured `humidity` and `temperature` are always reported.
#'
#' `qc_pass` is the conjunction of the integrity checks above
#' (`files_complete`, `roi_count_match`, `roi_data_complete`,
#' `runtime_consistent`, `volume_ok`).
#'
#' @param sample Sample(s) to check. Either a single directory (all `.adc`
#'   files within are discovered recursively), or a character vector of sample
#'   base names or paths (with or without a `.hdr`/`.adc`/`.roi` extension).
#'   When `data_folder` is supplied, bare sample names are resolved against it.
#' @param data_folder Optional directory in which to locate the triplet files
#'   when `sample` is given as bare sample names. Searched recursively.
#' @param max_ml Optional fixed upper bound (in millilitres) for a plausible
#'   analyzed volume, applied to every sample. Default `NULL` derives the ceiling
#'   per sample from the header syringe volume (`SyringeSampleVolume`, falling
#'   back to `syringeSize`, then the 5 mL IFCB standard) scaled by
#'   `volume_tolerance`. Set this only to override that instrument-reported
#'   value.
#' @param volume_tolerance Fractional tolerance added to the derived syringe
#'   volume ceiling (default `0.05`, i.e. 5%) to absorb estimation noise in the
#'   analyzed volume. Ignored when `max_ml` is supplied.
#' @param runtime_tolerance Maximum allowed fractional difference between the
#'   header and ADC run times before `runtime_consistent` is set to `FALSE`
#'   (default `0.02`, i.e. 2%).
#' @param max_roi_mb Optional numeric upper bound (in megabytes, where
#'   1 MB = 1024^2 bytes) for the `.roi` file size. When supplied, samples whose
#'   `.roi` exceeds this size are flagged in the advisory `roi_oversized` column
#'   (e.g. `max_roi_mb = 5` for 5 MB). Default `NULL` disables the check
#'   (`roi_oversized` is `NA`).
#' @param max_humidity Optional numeric threshold (percent) for the header's
#'   recorded `humidity`. Samples above it are flagged in the advisory
#'   `humidity_high` column. Default `NULL` disables the check.
#' @param max_temperature Optional numeric threshold (degrees, as recorded by
#'   the instrument) for the header's `temperature`. Samples above it are
#'   flagged in the advisory `temperature_high` column. Default `NULL` disables
#'   the check.
#' @param flowrate Syringe flow rate (millilitres per minute) passed to
#'   [ifcb_volume_analyzed()]. Default `0.25`.
#'
#' @return A tibble with one row per sample containing the resolved file paths,
#'   QC metrics, boolean QC flags, and an overall `qc_pass` column.
#'
#' @seealso [ifcb_read_hdr_data()] [ifcb_volume_analyzed()]
#' @references Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic
#'   classification of phytoplankton sampled with imaging-in-flow cytometry.
#'   Limnol. Oceanogr: Methods 5, 204-216.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Check every sample in a data directory
#' qc <- ifcb_qc_sample("data/raw")
#'
#' # Keep only clean, non-bead samples for analysis
#' dplyr::filter(qc, qc_pass, !is_bead_run)
#' }
ifcb_qc_sample <- function(sample,
                           data_folder = NULL,
                           max_ml = NULL,
                           volume_tolerance = 0.05,
                           runtime_tolerance = 0.02,
                           max_roi_mb = NULL,
                           max_humidity = NULL,
                           max_temperature = NULL,
                           flowrate = 0.25) {

  if (!is.null(max_ml) && (!is.numeric(max_ml) || length(max_ml) != 1 || max_ml <= 0)) {
    cli_abort("{.arg max_ml} must be a single positive number (millilitres), or {.code NULL} to use the header syringe volume.")
  }
  if (!is.numeric(volume_tolerance) || length(volume_tolerance) != 1 || volume_tolerance < 0) {
    cli_abort("{.arg volume_tolerance} must be a single non-negative number (fraction, e.g. 0.05).")
  }
  if (!is.numeric(runtime_tolerance) || length(runtime_tolerance) != 1 || runtime_tolerance < 0) {
    cli_abort("{.arg runtime_tolerance} must be a single non-negative number (fraction, e.g. 0.02).")
  }
  if (!is.null(max_roi_mb)) {
    if (!is.numeric(max_roi_mb) || length(max_roi_mb) != 1 || max_roi_mb < 0) {
      cli_abort("{.arg max_roi_mb} must be a single non-negative number (megabytes), or {.code NULL}.")
    }
  }
  if (!is.null(max_humidity) && (!is.numeric(max_humidity) || length(max_humidity) != 1)) {
    cli_abort("{.arg max_humidity} must be a single number (percent), or {.code NULL}.")
  }
  if (!is.null(max_temperature) && (!is.numeric(max_temperature) || length(max_temperature) != 1)) {
    cli_abort("{.arg max_temperature} must be a single number (degrees), or {.code NULL}.")
  }

  base_paths <- resolve_sample_paths(sample, data_folder)

  if (length(base_paths) == 0) {
    cli_abort(c(
      "No IFCB samples found.",
      "i" = "Provide a directory containing {.file .adc} files, or sample names with {.arg data_folder}."
    ))
  }

  env <- environment()
  cli_progress_bar("Checking samples", total = length(base_paths), .envir = env)

  rows <- lapply(base_paths, function(bp) {
    cli_progress_update(.envir = env)
    qc_one_sample(bp, max_ml = max_ml, volume_tolerance = volume_tolerance,
                  runtime_tolerance = runtime_tolerance, max_roi_mb = max_roi_mb,
                  max_humidity = max_humidity, max_temperature = max_temperature,
                  flowrate = flowrate)
  })

  cli_progress_done(.envir = env)

  out <- dplyr::bind_rows(rows)

  # Integrity summary: the conjunction of the four hard checks. NA-safe
  # (a failed/missing check counts as a failure).
  out$qc_pass <- with(out, {
    ok <- files_complete &
      dplyr::coalesce(roi_count_match, FALSE) &
      dplyr::coalesce(roi_data_complete, FALSE) &
      dplyr::coalesce(runtime_consistent, FALSE) &
      dplyr::coalesce(volume_ok, FALSE)
    ok
  })

  out
}

#' Resolve sample inputs to triplet base paths (no extension)
#'
#' @keywords internal
#' @noRd
resolve_sample_paths <- function(sample, data_folder = NULL) {
  # A single directory: discover all samples from their .adc files.
  if (length(sample) == 1 && dir.exists(sample)) {
    adc <- list.files(sample, pattern = "\\.adc$", recursive = TRUE, full.names = TRUE)
    return(unique(sub("\\.adc$", "", adc)))
  }

  # Strip any triplet extension to obtain base names.
  bases <- sub("\\.(hdr|adc|roi)$", "", sample, ignore.case = TRUE)

  if (!is.null(data_folder)) {
    if (!dir.exists(data_folder)) {
      cli_abort("{.arg data_folder} does not exist: {.file {data_folder}}")
    }
    adc <- list.files(data_folder, pattern = "\\.adc$", recursive = TRUE, full.names = TRUE)
    adc_base <- sub("\\.adc$", "", adc)
    bases <- vapply(basename(bases), function(nm) {
      hit <- adc_base[basename(adc_base) == nm]
      if (length(hit) >= 1) hit[1] else NA_character_
    }, character(1))
    bases <- bases[!is.na(bases)]
  }

  unique(bases)
}

#' Assemble one QC row for a single sample base path
#'
#' @keywords internal
#' @noRd
qc_one_sample <- function(base_path, max_ml = NULL, volume_tolerance = 0.05,
                          runtime_tolerance = 0.02, max_roi_mb = NULL,
                          max_humidity = NULL, max_temperature = NULL,
                          flowrate = 0.25) {
  hdr_file <- paste0(base_path, ".hdr")
  adc_file <- paste0(base_path, ".adc")
  roi_file <- paste0(base_path, ".roi")

  has_hdr <- file.exists(hdr_file)
  has_adc <- file.exists(adc_file)
  has_roi <- file.exists(roi_file)

  # ---- Header scalars (reuse the existing reader) --------------------------
  sample_type <- NA_character_
  run_beads <- NA
  hdr_trigger_count <- NA_integer_
  hdr_roi_count <- NA_integer_
  runtime_s <- NA_real_
  ml_analyzed <- NA_real_
  syringe_ml <- NA_real_
  humidity <- NA_real_
  temperature <- NA_real_

  if (has_hdr) {
    hdr <- tryCatch(
      ifcb_read_hdr_data(hdr_file, verbose = FALSE),
      error = function(e) NULL
    )
    if (!is.null(hdr) && nrow(hdr) > 0) {
      sample_type <- hdr_chr(hdr, "sampleType")
      run_beads <- tolower(hdr_chr(hdr, "runBeads")) %in% "true"
      hdr_trigger_count <- hdr_int(hdr, "triggerCount")
      hdr_roi_count <- hdr_int(hdr, "roiCount")
      runtime_s <- hdr_num(hdr, "runTime")
      # Configured sample volume per syringe; falls back to the syringe size.
      syringe_ml <- hdr_num(hdr, "SyringeSampleVolume")
      if (is.na(syringe_ml)) syringe_ml <- hdr_num(hdr, "syringeSize")
      humidity <- hdr_num(hdr, "humidity")
      temperature <- hdr_num(hdr, "temperature")
    }
    # Volume needs the ADC too unless we fall back to header-only.
    ml_analyzed <- tryCatch(
      ifcb_volume_analyzed(hdr_file, hdrOnly_flag = !has_adc, flowrate = flowrate),
      error = function(e) NA_real_
    )
  }

  # ---- ADC-derived counts and expected ROI byte extent ---------------------
  n_targets <- NA_integer_
  n_rois <- NA_integer_
  roi_bytes_expected <- NA_real_
  adc_runtime <- NA_real_

  if (has_adc) {
    adc <- tryCatch(read_adc_columns(adc_file), error = function(e) NULL)
    if (!is.null(adc)) {
      n_targets <- nrow(adc)
      rc <- adc_get_roi_columns(adc)
      imaged <- rc$x > 0
      n_rois <- sum(imaged)
      roi_bytes_expected <- if (n_rois > 0) max(rc$startbyte[imaged] + rc$x[imaged] * rc$y[imaged]) else 0
      adc_runtime <- adc_get_runtime(adc)
    }
  }

  roi_bytes <- if (has_roi) as.numeric(file.size(roi_file)) else NA_real_

  # ---- Flags ---------------------------------------------------------------
  files_complete <- has_hdr && has_adc && has_roi
  roi_count_match <- if (!is.na(n_rois) && !is.na(hdr_roi_count)) n_rois == hdr_roi_count else NA
  roi_data_complete <- if (has_roi && !is.na(roi_bytes_expected)) roi_bytes >= roi_bytes_expected else NA

  # Volume ceiling: an explicit max_ml wins; otherwise derive from the header
  # syringe volume (with tolerance), falling back to the 5 mL IFCB standard.
  volume_ceiling <- if (!is.null(max_ml)) {
    max_ml
  } else {
    base_ml <- if (!is.na(syringe_ml)) syringe_ml else 5
    base_ml * (1 + volume_tolerance)
  }
  volume_ok <- !is.na(ml_analyzed) && ml_analyzed > 0 && ml_analyzed <= volume_ceiling

  # Header and ADC must report the same run time (within tolerance); a mismatch
  # indicates corrupted or mismatched metadata.
  runtime_consistent <- if (!is.na(runtime_s) && !is.na(adc_runtime) &&
                            runtime_s > 0 && adc_runtime > 0) {
    abs(runtime_s - adc_runtime) / runtime_s <= runtime_tolerance
  } else NA
  is_empty <- if (!is.na(n_rois)) n_rois == 0 else NA
  is_bead_run <- isTRUE(run_beads) || (!is.na(sample_type) && grepl("bead", sample_type, ignore.case = TRUE))
  roi_oversized <- if (!is.null(max_roi_mb) && has_roi) roi_bytes > max_roi_mb * 1024^2 else NA
  humidity_high <- if (!is.null(max_humidity) && !is.na(humidity)) humidity > max_humidity else NA
  temperature_high <- if (!is.null(max_temperature) && !is.na(temperature)) temperature > max_temperature else NA

  looktime_s <- if (has_hdr) {
    rt <- ifcb_get_runtime(hdr_file)
    if (!is.null(rt$runtime) && !is.null(rt$inhibittime)) rt$runtime - rt$inhibittime else NA_real_
  } else NA_real_

  dplyr::tibble(
    sample = basename(base_path),
    hdr_file = if (has_hdr) hdr_file else NA_character_,
    adc_file = if (has_adc) adc_file else NA_character_,
    roi_file = if (has_roi) roi_file else NA_character_,
    has_hdr = has_hdr,
    has_adc = has_adc,
    has_roi = has_roi,
    sample_type = sample_type,
    run_beads = run_beads,
    hdr_trigger_count = hdr_trigger_count,
    hdr_roi_count = hdr_roi_count,
    n_targets = n_targets,
    n_rois = n_rois,
    roi_bytes = roi_bytes,
    roi_bytes_expected = roi_bytes_expected,
    runtime_s = runtime_s,
    looktime_s = looktime_s,
    ml_analyzed = ml_analyzed,
    syringe_ml = syringe_ml,
    humidity = humidity,
    temperature = temperature,
    files_complete = files_complete,
    roi_count_match = roi_count_match,
    roi_data_complete = roi_data_complete,
    runtime_consistent = runtime_consistent,
    volume_ok = volume_ok,
    is_empty = is_empty,
    is_bead_run = is_bead_run,
    roi_oversized = roi_oversized,
    humidity_high = humidity_high,
    temperature_high = temperature_high
  )
}

#' Extract the run time (seconds) from a parsed ADC table
#'
#' Internal helper. Returns the maximum of the ADC `RunTime` column (named from
#' the header `ADCFileFormat`, with a positional fallback for the standard new
#' format), or `NA` when the column is unavailable.
#'
#' @param adc A data frame from `read_adc_columns()`.
#' @return A single numeric run time in seconds, or `NA`.
#' @keywords internal
#' @noRd
adc_get_runtime <- function(adc) {
  cn <- tolower(names(adc))
  idx <- which(cn == "runtime")
  if (length(idx) != 1) {
    # New ADC format: RunTime is column 23; older formats lack it.
    if (ncol(adc) >= 23) idx <- 23 else return(NA_real_)
  }
  vals <- suppressWarnings(as.numeric(adc[[idx]]))
  if (all(is.na(vals))) NA_real_ else max(vals, na.rm = TRUE)
}

# Safe scalar accessors for a one-row hdr tibble (column may be absent) --------
#' @keywords internal
#' @noRd
hdr_chr <- function(hdr, key) {
  if (key %in% names(hdr)) as.character(hdr[[key]][1]) else NA_character_
}
#' @keywords internal
#' @noRd
hdr_int <- function(hdr, key) {
  if (key %in% names(hdr)) suppressWarnings(as.integer(as.character(hdr[[key]][1]))) else NA_integer_
}
#' @keywords internal
#' @noRd
hdr_num <- function(hdr, key) {
  if (key %in% names(hdr)) suppressWarnings(as.numeric(as.character(hdr[[key]][1]))) else NA_real_
}
