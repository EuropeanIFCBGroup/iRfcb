utils::globalVariables("bin")
#' Extract Slim Features and Blobs from IFCB Data
#'
#' This function computes the "slim" feature set (version 4) and blob masks from
#' raw Imaging FlowCytobot (IFCB) data by calling the WHOI `ifcb-features` Python
#' package. For each bin it writes a feature table
#' (`<bin>_features_v4.csv`, 30 morphological features per region of interest)
#' and an archive of binary blob masks (`<bin>_blobs_v4.zip`, one 1-bit PNG per
#' ROI). Features and blobs are written to separate, user-specified directories.
#'
#' @details
#' This function wraps the `extract_slim_features` workflow from the
#' `ifcb-features` Python repository, which can be found at
#' \url{https://github.com/WHOIGit/ifcb-features}.
#'
#' Python and the `ifcb-features` package must be installed to use this function.
#' The required Python packages can be installed in a virtual environment using
#' `ifcb_py_install(features = TRUE)`, which additionally installs `ifcb-features`
#' and its dependencies (a raw-data reader, `phasepack`, `scikit-image`,
#' `scikit-learn`).
#'
#' **Supported `ifcb-features` versions:** raw data is read through whichever
#' reader the installed `ifcb-features` release provides - `ifcbkit` for v1.1.0
#' and later, `pyifcb` for v1.0.0 and earlier. Both are supported and may be
#' installed side by side, with `ifcbkit` preferred when both are present. Use
#' the `backend` argument (or the `IRFCB_IFCB_BACKEND` environment variable) to
#' force a particular reader.
#'
#' The feature code itself is unchanged between these releases, so the choice of
#' reader does not affect how a region of interest is measured. The readers do
#' not agree in every case, however: `pyifcb` skips a ROI whose recorded width is
#' zero, while `ifcbkit` skips one whose width *or* height is zero, and `ifcbkit`
#' additionally stitches overlapping ROI pairs in older I-style bins, which
#' `pyifcb` returns separately. For the D-style bins produced by current
#' instruments the two agree on ROI numbering and pixel data, and outputs are
#' interchangeable; for I-style data, pin a reader with `backend` if you need
#' results comparable to an earlier run.
#'
#' **Python version requirement:** `ifcb-features` requires Python >= 3.10.
#' Installing v1.0.0 or earlier additionally pulls in `pyifcb`, which needs a
#' binary `h5py` wheel (available for Python 3.10-3.13). See
#' \url{https://github.com/WHOIGit/ifcb-features} for current requirements, and
#' use `ifcb_py_install(features = TRUE)` to install into a compatible
#' environment.
#'
#' **Multiblob output:** the slim feature table describes each ROI's largest
#' blob (plus `summed*` columns over all blobs). With `multiblob = TRUE`, the
#' per-blob features of every blob in a multi-blob ROI are additionally written
#' to `multiblob/<bin>_multiblob_v4.csv` inside `features_folder`, one row per
#' blob with `roi_number`, `blob_number` and 18 morphological columns - the
#' sidecar output `ifcb-features` introduced in v1.2.0, which is also the
#' minimum version required (older releases never compute per-blob rows, and
#' the function stops with an error if one is installed; update with
#' `ifcb_py_install(features = TRUE)`). As upstream, a bin in which no ROI has
#' more than one blob gets no sidecar file at all, so the presence of a
#' `<bin>_multiblob_v4.csv` means that bin genuinely contains multi-blob ROIs.
#' The skip logic accounts for this by reading the `numBlobs` column of a
#' bin's existing feature CSV to tell whether a sidecar is expected:
#' re-running with `multiblob = TRUE` over a directory previously extracted
#' without it therefore skips the bins with single-blob ROIs only and
#' re-extracts just those that need a sidecar, without `overwrite = TRUE`.
#'
#' Bins are processed sequentially by default. When `parallel = TRUE`, bins are
#' distributed across `n_cores` workers, which can substantially reduce runtime
#' for large datasets. Existing outputs are skipped unless `overwrite = TRUE`,
#' so the function can be re-run to resume an interrupted extraction.
#'
#' The parallel backend depends on the platform. On Linux, bins run in separate
#' worker processes, giving true multi-core parallelism. On Windows and macOS,
#' where the embedded Python interpreter cannot reliably spawn worker processes,
#' a thread pool is used instead; because of Python's Global Interpreter Lock the
#' speedup there is smaller and depends on how much of the work runs in native
#' (`numpy` / `scikit-image`) code. A further consequence of the thread backend
#' is that interrupting a run (ESC / Stop) does not halt a bin already being
#' processed: it finishes and writes its outputs before the run stops.
#'
#' @param data_folder The path to a directory containing raw IFCB data
#'   (`.roi`, `.adc` and `.hdr` files). The directory is searched recursively by
#'   the raw-data reader, so nested data structures are supported.
#' @param features_folder The path to the directory where the
#'   `<bin>_features_v4.csv` files will be written. Created if it does not exist.
#' @param blobs_folder The path to the directory where the `<bin>_blobs_v4.zip`
#'   files will be written. Created if it does not exist.
#' @param bins An optional character vector of bin names (e.g.
#'   `"D20220522T003051_IFCB134"`) to restrict processing to a subset of bins.
#'   If `NULL` (default), all bins found in `data_folder` are processed.
#' @param parallel A logical indicating whether to process bins in parallel.
#'   Default is `FALSE`.
#' @param n_cores An integer specifying the number of parallel workers to use
#'   when `parallel = TRUE` (worker processes on Linux, threads on Windows and
#'   macOS; see Details). If `NULL` (default), `parallel::detectCores() - 1`
#'   workers are used. Ignored when `parallel = FALSE`.
#' @param overwrite A logical indicating whether to overwrite existing feature
#'   and blob files. If `FALSE` (default), bins whose outputs already exist are
#'   skipped.
#' @param feature_tag A string controlling the token between the bin lid and the
#'   version in the feature file name. `"features"` (default) writes
#'   `<bin>_features_v4.csv` (the upstream `ifcb-features` convention);
#'   `"fea"` writes `<bin>_fea_v4.csv`, the name the IFCB Dashboard
#'   (`ifcbdb` / `pyifcb`'s `FeaturesDirectory`) searches for. Use `"fea"` when
#'   the output is destined for an IFCB Dashboard instance; remember the dataset
#'   directory there must be registered with product version 4 to match the
#'   `_v4` suffix. The blob archive name (`<bin>_blobs_v4.zip`) is unaffected.
#' @param multiblob A logical indicating whether to additionally write
#'   `multiblob/<bin>_multiblob_v4.csv` files (per-blob features for regions of
#'   interest with more than one blob) inside `features_folder`. Bins without
#'   multi-blob ROIs get no sidecar file, as in upstream `ifcb-features`.
#'   Requires `ifcb-features` v1.2.0 or later; see Details. Default is `FALSE`.
#' @param backend An optional string forcing the raw-data reader, either
#'   `"ifcbkit"` or `"pyifcb"`. If `NULL` (default), the `IRFCB_IFCB_BACKEND`
#'   environment variable is used when set, otherwise the preferred available
#'   reader (`ifcbkit` when both are installed). See Details for the cases in
#'   which the two readers differ.
#' @param verbose A logical indicating whether to print progress messages,
#'   including a progress bar that advances as each bin is processed.
#'   Default is `TRUE`.
#'
#' @return Invisibly returns a tibble with one row per bin and the columns
#'   `bin`, `status` (`"processed"`, `"skipped"` or `"error"`) and `message`.
#'   The function is primarily called for its side effect of writing feature and
#'   blob files to disk.
#'
#' @seealso \code{\link{ifcb_py_install}}, \code{\link{ifcb_read_features}},
#'   \url{https://github.com/WHOIGit/ifcb-features}
#'
#' @examples
#' \dontrun{
#' # Install the Python environment including ifcb-features
#' ifcb_py_install(features = TRUE)
#'
#' # Extract features and blobs from all bins in a data folder
#' ifcb_extract_features(
#'   data_folder = "path/to/data",
#'   features_folder = "path/to/features",
#'   blobs_folder = "path/to/blobs"
#' )
#'
#' # Process a subset of bins in parallel using 4 cores
#' ifcb_extract_features(
#'   data_folder = "path/to/data",
#'   features_folder = "path/to/features",
#'   blobs_folder = "path/to/blobs",
#'   bins = c("D20220522T003051_IFCB134", "D20220522T000439_IFCB134"),
#'   parallel = TRUE,
#'   n_cores = 4
#' )
#'
#' # Write IFCB Dashboard-compatible feature names (<bin>_fea_v4.csv)
#' ifcb_extract_features(
#'   data_folder = "path/to/data",
#'   features_folder = "path/to/features",
#'   blobs_folder = "path/to/blobs",
#'   feature_tag = "fea"
#' )
#'
#' # Also write per-blob features for multi-blob ROIs
#' # (path/to/features/multiblob/<bin>_multiblob_v4.csv;
#' # requires ifcb-features >= 1.2.0)
#' ifcb_extract_features(
#'   data_folder = "path/to/data",
#'   features_folder = "path/to/features",
#'   blobs_folder = "path/to/blobs",
#'   multiblob = TRUE
#' )
#' }
#'
#' @export
ifcb_extract_features <- function(data_folder,
                                  features_folder,
                                  blobs_folder,
                                  bins = NULL,
                                  parallel = FALSE,
                                  n_cores = NULL,
                                  overwrite = FALSE,
                                  feature_tag = c("features", "fea"),
                                  multiblob = FALSE,
                                  backend = NULL,
                                  verbose = TRUE) {

  feature_tag <- match.arg(feature_tag)
  # Fall back to the environment variable, read here rather than in Python:
  # Python snapshots os.environ at interpreter start, so a Sys.setenv() call
  # made from R after Python has initialised would never reach it.
  if (is.null(backend)) {
    env_backend <- Sys.getenv("IRFCB_IFCB_BACKEND", unset = "")
    if (nzchar(env_backend)) backend <- env_backend
  }
  if (!is.null(backend)) {
    backend <- match.arg(backend, c("ifcbkit", "pyifcb"))
  }

  if (!dir.exists(data_folder)) {
    cli_abort("{.arg data_folder} does not exist: {.file {data_folder}}")
  }

  if (!reticulate::py_available(initialize = TRUE)) {
    cli_abort(c(
      "Python is not available.",
      "i" = "Install Python and run {.fn ifcb_py_install} to use this function."
    ))
  }

  # Check that the ifcb-features Python packages can be imported. These are
  # installed from GitHub (a VCS install), which `reticulate::py_list_packages()`
  # does not always report, so we import the module names directly rather than
  # checking the pip distribution names. Importing also surfaces broken
  # installations (e.g. a numpy/scipy ABI mismatch), which a simple availability
  # check would silently report as "missing".
  import_error <- tryCatch({
    reticulate::import("ifcb_features", delay_load = FALSE)
    NULL
  }, error = function(e) conditionMessage(e))

  if (!is.null(import_error)) {
    cli_abort(c(
      "The required Python module {.val ifcb_features} could not be loaded.",
      "x" = import_error,
      "i" = "Install or repair the WHOI {.pkg ifcb-features} package with {.code ifcb_py_install(features = TRUE)}."
    ))
  }

  # The raw-data reader depends on the ifcb-features version: releases >= 1.1.0
  # depend on 'ifcbkit', earlier ones on 'pyifcb' (imported as 'ifcb'). Either
  # is accepted, so one iRfcb installation works with both.
  reader_errors <- vapply(c("ifcbkit", "ifcb"), function(mod) {
    tryCatch({
      reticulate::import(mod, delay_load = FALSE)
      NA_character_
    }, error = function(e) conditionMessage(e))
  }, character(1))

  if (all(!is.na(reader_errors))) {
    cli_abort(c(
      "No IFCB raw-data reader could be loaded.",
      "x" = "{.val ifcbkit}: {reader_errors[['ifcbkit']]}",
      "x" = "{.val ifcb}: {reader_errors[['ifcb']]}",
      "i" = "Install or repair the WHOI {.pkg ifcb-features} package with {.code ifcb_py_install(features = TRUE)}."
    ))
  }

  # Create output directories if needed
  if (!dir.exists(features_folder)) {
    dir.create(features_folder, recursive = TRUE)
  }
  if (!dir.exists(blobs_folder)) {
    dir.create(blobs_folder, recursive = TRUE)
  }

  # Determine the number of worker processes
  if (parallel) {
    if (is.null(n_cores)) {
      n_cores <- max(1, parallel::detectCores() - 1)
    }
    num_workers <- as.integer(n_cores)
  } else {
    num_workers <- 1L
  }

  # Import the Python module
  py_mod <- reticulate::import_from_path(
    "extract_slim_features",
    path = system.file("python", package = "iRfcb"),
    delay_load = FALSE
  )

  # Multiblob output exists from ifcb-features v1.2.0 on; older releases never
  # compute per-blob rows, so this cannot be emulated for them. The version is
  # identified structurally: BLOB_FEATURE_COLUMNS was added to ifcb_features.all
  # in v1.2.0 together with the multiblob output, and the Python module sets it
  # to None when the import fails.
  if (isTRUE(multiblob) && is.null(py_mod$BLOB_FEATURE_COLUMNS)) {
    cli_abort(c(
      "{.code multiblob = TRUE} requires {.pkg ifcb-features} v1.2.0 or later.",
      "x" = "The installed release does not produce multiblob output.",
      "i" = "Update to the latest release with {.code ifcb_py_install(features = TRUE)}."
    ))
  }

  py_bins <- if (is.null(bins)) NULL else as.list(as.character(bins))

  if (parallel) {
    # Parallel extraction is driven from R so that a user interrupt is handled
    # at the R level. The pool is created in Python, but the polling loop runs
    # in R and `on.exit()` guarantees the worker processes are terminated on
    # normal completion, an error, or a user interrupt (ESC / Stop) - otherwise
    # abandoned workers would keep writing files in the background.

    # Scan the data directory once to get the bin list. This can take time for
    # large directories, so we show a message immediately and pass the resolved
    # list into ParallelExtractor to avoid a second scan.
    if (verbose) cli_alert_info("Scanning data directory...")
    bin_info <- py_mod$list_bins(as.character(data_folder), bins = py_bins,
                                 backend = backend)
    n_bins <- length(bin_info$found)
    pb <- NULL
    if (verbose && n_bins > 0) {
      pb <- cli_progress_bar(
        sprintf("Extracting features and blobs (%d workers)", num_workers),
        total = n_bins
      )
      cli_progress_update(id = pb, set = 0L)  # force immediate render before workers start
    }

    # Process pools spawned from an embedded interpreter (reticulate) hang on
    # Windows and macOS, so fall back to a thread pool there. Linux uses fork and
    # keeps the (faster) process pool. See ParallelExtractor in the Python module.
    use_threads <- .Platform$OS.type == "windows" ||
      identical(Sys.info()[["sysname"]], "Darwin")

    extractor <- py_mod$ParallelExtractor(
      data_directory     = as.character(data_folder),
      features_directory = as.character(features_folder),
      blobs_directory    = as.character(blobs_folder),
      overwrite          = overwrite,
      num_workers        = num_workers,
      found_bins         = as.list(bin_info$found),
      missing_bins       = as.list(bin_info$missing),
      python_executable  = reticulate::py_exe(),
      use_threads        = use_threads,
      feature_tag        = feature_tag,
      backend            = backend,
      multiblob          = multiblob
    )
    on.exit(try(extractor$terminate(), silent = TRUE), add = TRUE)

    # Requested bins that were not found are reported as errors
    results <- lapply(extractor$missing, function(b) {
      list(bin = b, status = "error", message = "bin not found in data directory")
    })

    done <- 0L
    while (extractor$remaining() > 0) {
      new_results <- extractor$poll()
      if (length(new_results) > 0) {
        results <- c(results, new_results)
        done <- done + length(new_results)
        if (!is.null(pb)) cli_progress_update(id = pb, set = done)
      }
      if (extractor$remaining() > 0) Sys.sleep(0.05)
    }
    if (!is.null(pb)) cli_progress_done(id = pb)
  } else {
    # Sequential extraction: a single Python call drives the progress bar via a
    # callback invoked after each bin completes.
    pb <- NULL
    progress_cb <- NULL
    if (verbose) {
      n_bins <- length(py_mod$list_bins(as.character(data_folder), bins = py_bins,
                                        backend = backend)$found)
      if (n_bins > 0) {
        pb <- cli_progress_bar("Extracting features and blobs", total = n_bins)
        progress_cb <- function(done, total) {
          cli_progress_update(id = pb, set = as.integer(done))
        }
      }
    }

    results <- py_mod$extract_features(
      data_directory = as.character(data_folder),
      features_directory = as.character(features_folder),
      blobs_directory = as.character(blobs_folder),
      bins = py_bins,
      overwrite = overwrite,
      num_workers = 1L,
      progress = progress_cb,
      feature_tag = feature_tag,
      backend = backend,
      multiblob = multiblob
    )

    if (!is.null(pb)) cli_progress_done(id = pb)
  }

  # Convert the list of per-bin result dicts into a tibble
  results_df <- dplyr::bind_rows(lapply(results, function(x) {
    dplyr::tibble(
      bin = as.character(x$bin),
      status = as.character(x$status),
      message = as.character(x$message)
    )
  }))

  if (nrow(results_df) > 0) {
    results_df <- dplyr::arrange(results_df, bin)
  }

  if (verbose) {
    n_processed <- sum(results_df$status == "processed")
    n_skipped <- sum(results_df$status == "skipped")
    n_error <- sum(results_df$status == "error")

    cli_alert_success("Processed {n_processed} bin{?s}.")
    if (n_skipped > 0) {
      cli_alert_info("Skipped {n_skipped} existing bin{?s} (use {.code overwrite = TRUE} to recompute).")
    }
    if (n_error > 0) {
      cli_alert_warning("{n_error} bin{?s} failed. See the returned data frame for details.")
    }
  }

  invisible(results_df)
}
