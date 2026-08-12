test_that("ifcb_extract_features extracts features and blobs", {
  # Skip if Python or ifcb-features is not available
  skip_if_no_python()
  skip_if_no_ifcb_features()
  skip_on_cran()

  skip_if(Sys.getenv("SKIP_PYTHON_TESTS") == "true",
          "Skipping Python-dependent tests: missing Python packages or running on CRAN.")

  # Create a temporary directory and unzip the test data
  temp_dir <- file.path(tempdir(), "ifcb_extract_features")
  test_data_zip <- test_path("test_data/test_data.zip")
  expect_true(file.exists(test_data_zip))
  unzip(test_data_zip, exdir = temp_dir)

  data_folder <- file.path(temp_dir, "test_data/data")
  features_folder <- file.path(temp_dir, "features_out")
  blobs_folder <- file.path(temp_dir, "blobs_out")

  bin <- "D20220522T003051_IFCB134"  # bin with .roi/.adc/.hdr in test data

  result <- ifcb_extract_features(
    data_folder = data_folder,
    features_folder = features_folder,
    blobs_folder = blobs_folder,
    bins = bin,
    verbose = FALSE
  )

  features_file <- file.path(features_folder, paste0(bin, "_features_v4.csv"))
  blobs_file <- file.path(blobs_folder, paste0(bin, "_blobs_v4.zip"))

  # Outputs are written to the separate, specified folders
  expect_true(dir.exists(features_folder))
  expect_true(dir.exists(blobs_folder))
  expect_true(file.exists(features_file))
  expect_true(file.exists(blobs_file))

  # Result reports the bin as processed
  expect_s3_class(result, "data.frame")
  expect_equal(result$status[result$bin == bin], "processed")

  # The features CSV has the expected slim feature columns
  features <- readr::read_csv(features_file, show_col_types = FALSE)
  expect_true(all(c("roi_number", "Area", "Biovolume", "Perimeter") %in% names(features)))
  expect_equal(ncol(features), 31)  # roi_number + 30 feature columns
})

test_that("ifcb_extract_features skips existing outputs unless overwrite = TRUE", {
  skip_if_no_python()
  skip_if_no_ifcb_features()
  skip_on_cran()

  skip_if(Sys.getenv("SKIP_PYTHON_TESTS") == "true",
          "Skipping Python-dependent tests: missing Python packages or running on CRAN.")

  temp_dir <- file.path(tempdir(), "ifcb_extract_features_overwrite")
  unzip(test_path("test_data/test_data.zip"), exdir = temp_dir)

  data_folder <- file.path(temp_dir, "test_data/data")
  features_folder <- file.path(temp_dir, "features_out")
  blobs_folder <- file.path(temp_dir, "blobs_out")
  bin <- "D20220522T003051_IFCB134"

  # First run creates the outputs
  ifcb_extract_features(data_folder, features_folder, blobs_folder,
                        bins = bin, verbose = FALSE)
  features_file <- file.path(features_folder, paste0(bin, "_features_v4.csv"))
  first_mtime <- file.mtime(features_file)

  # Second run without overwrite should skip and leave the file untouched
  result_skip <- ifcb_extract_features(data_folder, features_folder, blobs_folder,
                                       bins = bin, overwrite = FALSE, verbose = FALSE)
  expect_equal(result_skip$status[result_skip$bin == bin], "skipped")
  expect_equal(file.mtime(features_file), first_mtime)

  # Run with overwrite should regenerate the file
  Sys.sleep(1.1)  # ensure mtime resolution can register a change
  result_over <- ifcb_extract_features(data_folder, features_folder, blobs_folder,
                                       bins = bin, overwrite = TRUE, verbose = FALSE)
  expect_equal(result_over$status[result_over$bin == bin], "processed")
  expect_gt(as.numeric(file.mtime(features_file)), as.numeric(first_mtime))
})

test_that("ifcb_extract_features errors on missing data_folder", {
  expect_error(
    ifcb_extract_features("nonexistent_folder", tempfile(), tempfile()),
    "does not exist"
  )
})

test_that("ifcb_extract_features aborts when Python is unavailable", {
  mockery::stub(ifcb_extract_features, "reticulate::py_available", FALSE)
  expect_error(
    ifcb_extract_features(tempdir(), tempfile(), tempfile()),
    "Python is not available"
  )
})

test_that("ifcb_extract_features aborts when ifcb-features module cannot be imported", {
  mockery::stub(ifcb_extract_features, "reticulate::py_available", TRUE)
  mockery::stub(ifcb_extract_features, "reticulate::import", function(mod, ...) {
    stop(paste("No module named", shQuote(mod)))
  })
  expect_error(
    ifcb_extract_features(tempdir(), tempfile(), tempfile()),
    "could not be loaded"
  )
})

test_that("ifcb_extract_features emits verbose output", {
  skip_if_no_python()
  skip_if_no_ifcb_features()
  skip_on_cran()

  skip_if(Sys.getenv("SKIP_PYTHON_TESTS") == "true",
          "Skipping Python-dependent tests: missing Python packages or running on CRAN.")

  temp_dir <- file.path(tempdir(), "ifcb_extract_features_verbose")
  unzip(test_path("test_data/test_data.zip"), exdir = temp_dir)

  data_folder <- file.path(temp_dir, "test_data/data")
  features_folder <- file.path(temp_dir, "features_out")
  blobs_folder <- file.path(temp_dir, "blobs_out")
  bin <- "D20220522T003051_IFCB134"

  expect_no_error(
    ifcb_extract_features(data_folder, features_folder, blobs_folder,
                          bins = bin, verbose = TRUE)
  )
})

test_that("ifcb_extract_features runs in parallel with n_cores = NULL", {
  skip_if_no_python()
  skip_if_no_ifcb_features()
  skip_on_cran()

  skip_if(Sys.getenv("SKIP_PYTHON_TESTS") == "true",
          "Skipping Python-dependent tests: missing Python packages or running on CRAN.")

  temp_dir <- file.path(tempdir(), "ifcb_extract_features_parallel")
  unzip(test_path("test_data/test_data.zip"), exdir = temp_dir)

  data_folder <- file.path(temp_dir, "test_data/data")
  features_folder <- file.path(temp_dir, "features_out")
  blobs_folder <- file.path(temp_dir, "blobs_out")
  bin <- "D20220522T003051_IFCB134"

  result <- ifcb_extract_features(
    data_folder = data_folder,
    features_folder = features_folder,
    blobs_folder = blobs_folder,
    bins = bin,
    parallel = TRUE,
    n_cores = NULL,
    verbose = TRUE
  )

  expect_equal(result$status[result$bin == bin], "processed")
})

test_that("feature columns are numeric (complex eigenvalues are not written to CSV)", {
  # ifcb_features derives the ellipse properties from numpy.linalg.eig, which
  # returns complex eigenvalues from numpy 2.3 onwards. Without the real-part
  # coercion in extract_slim_features.py, Eccentricity, MajorAxisLength and
  # MinorAxisLength are written as "(0.79+0j)" strings, silently turning
  # numeric columns into text.
  skip_if_no_python()
  skip_if_no_ifcb_features()
  skip_on_cran()

  skip_if(Sys.getenv("SKIP_PYTHON_TESTS") == "true",
          "Skipping Python-dependent tests: missing Python packages or running on CRAN.")

  temp_dir <- file.path(tempdir(), "ifcb_extract_features_numeric")
  unzip(test_path("test_data/test_data.zip"), exdir = temp_dir)

  bin <- "D20220522T003051_IFCB134"
  features_folder <- file.path(temp_dir, "features_out")

  ifcb_extract_features(
    data_folder = file.path(temp_dir, "test_data/data"),
    features_folder = features_folder,
    blobs_folder = file.path(temp_dir, "blobs_out"),
    bins = bin,
    verbose = FALSE
  )

  features <- utils::read.csv(
    file.path(features_folder, paste0(bin, "_features_v4.csv")))

  affected <- c("Eccentricity", "MajorAxisLength", "MinorAxisLength")
  expect_true(all(affected %in% names(features)))
  expect_true(all(vapply(features[affected], is.numeric, logical(1))))
  expect_true(all(vapply(features, is.numeric, logical(1))))
})

test_that("a degenerate blob measures zero, as it does with upstream ifcb-features", {
  # ifcb-features <= v1.1.1 derives the axis lengths as 4 * sqrt(eigenvalue) via
  # numpy.linalg.eig. A collinear blob can yield a slightly negative eigenvalue,
  # putting the axis length on the imaginary axis. Upstream (PR #20) guards the
  # same case by clipping the radicand to zero, so iRfcb must report 0 too:
  # anything else would make the measurement depend on which ifcb-features
  # release happens to be installed.
  #
  # This exercises _real_valued() directly rather than a whole extraction run,
  # but still needs ifcb-features installed, because extract_slim_features.py
  # imports ifcb_features.all at module scope.
  skip_if_no_python()
  skip_if_no_ifcb_features()
  skip_on_cran()

  skip_if(Sys.getenv("SKIP_PYTHON_TESTS") == "true",
          "Skipping Python-dependent tests: missing Python packages or running on CRAN.")

  extract <- reticulate::import_from_path(
    "extract_slim_features",
    path = system.file("python", package = "iRfcb"),
    delay_load = FALSE
  )

  # _real_valued() takes and returns (name, value) pairs; flatten them to a
  # named numeric vector so the values can be compared directly.
  real_valued <- function(python_pairs) {
    out <- extract$`_real_valued`(reticulate::py_eval(python_pairs, convert = FALSE))
    stats::setNames(vapply(out, function(pair) pair[[2]], numeric(1)),
                    vapply(out, function(pair) pair[[1]], character(1)))
  }

  # What ifcb-features v1.1.1 returns for a collinear blob: a purely imaginary
  # minor axis, a real major axis carried in a complex type, and a plain float.
  values <- real_valued(paste0(
    '[("MinorAxisLength", complex(0, 7.62939453e-06)),',
    ' ("MajorAxisLength", complex(720.2434592, 0)),',
    ' ("Eccentricity", complex(1, 0)),',
    ' ("Area", 42.0)]'
  ))

  expect_equal(values[["MinorAxisLength"]], 0)   # clipped, not NaN
  expect_false(is.na(values[["MinorAxisLength"]]))
  expect_equal(values[["MajorAxisLength"]], 720.2434592)
  expect_equal(values[["Eccentricity"]], 1)
  expect_equal(values[["Area"]], 42)             # non-complex, passed through

  # The property that matters for reproducibility: once upstream tags a release
  # with its fix, the same blob arrives already real and this coercion becomes a
  # no-op. Both inputs must produce the same output, or upgrading
  # ifcb-features would silently shift the reported values.
  expect_equal(
    real_valued('[("MinorAxisLength", complex(0, 7.62939453e-06))]'),
    real_valued('[("MinorAxisLength", 0.0)]')
  )
})

test_that("the compute_features result is unpacked for both ifcb-features APIs", {
  # ifcb-features v1.2.0 (multiblob output, upstream PR #22) changed
  # compute_features from returning (blobs_image, features) to
  # (blobs_image, features, multiblob_rows). A direct 2-tuple unpack raises
  # ValueError on v1.2.0 for every ROI, and the per-ROI error handling would
  # swallow that into feature rows containing only roi_number — an extraction
  # that "succeeds" with empty output. _unpack_compute_features must accept
  # both shapes, normalising them to the 3-tuple form with an empty multiblob
  # element on releases that never compute per-blob rows.
  skip_if_no_python()
  skip_if_no_ifcb_features()
  skip_on_cran()

  skip_if(Sys.getenv("SKIP_PYTHON_TESTS") == "true",
          "Skipping Python-dependent tests: missing Python packages or running on CRAN.")

  extract <- reticulate::import_from_path(
    "extract_slim_features",
    path = system.file("python", package = "iRfcb"),
    delay_load = FALSE
  )

  unpack <- function(python_tuple) {
    extract$`_unpack_compute_features`(
      reticulate::py_eval(python_tuple, convert = FALSE)
    )
  }

  # The 2-tuple returned by ifcb-features v1.1.x and earlier.
  old_api <- unpack('("BLOBS_IMAGE", [("Area", 42.0)])')

  # The 3-tuple returned by v1.2.0.
  new_api <- unpack(paste0(
    '("BLOBS_IMAGE", [("Area", 42.0)],',
    ' [(1, {"Area": 21.0}), (2, {"Area": 21.0})])'
  ))

  expect_length(old_api, 3)
  expect_equal(old_api[[1]], "BLOBS_IMAGE")
  expect_equal(old_api[[2]][[1]][[1]], "Area")
  expect_equal(old_api[[2]][[1]][[2]], 42)
  expect_length(old_api[[3]], 0)

  # Both API versions must yield identical slim results, or upgrading
  # ifcb-features would silently change what the extraction writes; only the
  # per-blob element may differ, carrying the v1.2.0 multiblob rows through.
  expect_equal(old_api[1:2], new_api[1:2])
  expect_length(new_api[[3]], 2)
  expect_equal(new_api[[3]][[1]][[1]], 1)
  expect_equal(new_api[[3]][[1]][[2]]$Area, 21)
})

test_that("ifcb_extract_features writes multiblob sidecars when requested", {
  skip_if_no_python()
  skip_if_no_ifcb_features()
  skip_on_cran()

  skip_if(Sys.getenv("SKIP_PYTHON_TESTS") == "true",
          "Skipping Python-dependent tests: missing Python packages or running on CRAN.")

  # Multiblob output only exists from ifcb-features v1.2.0 on.
  extract <- reticulate::import_from_path(
    "extract_slim_features",
    path = system.file("python", package = "iRfcb"),
    delay_load = FALSE
  )
  skip_if(is.null(extract$BLOB_FEATURE_COLUMNS),
          "Installed ifcb-features predates multiblob output (v1.2.0).")

  temp_dir <- file.path(tempdir(), "ifcb_extract_features_multiblob")
  unzip(test_path("test_data/test_data.zip"), exdir = temp_dir)

  data_folder <- file.path(temp_dir, "test_data/data")
  features_folder <- file.path(temp_dir, "features_out")
  blobs_folder <- file.path(temp_dir, "blobs_out")
  bin <- "D20220522T003051_IFCB134"
  features_file <- file.path(features_folder, paste0(bin, "_features_v4.csv"))
  multiblob_file <- file.path(features_folder, "multiblob",
                              paste0(bin, "_multiblob_v4.csv"))

  # A run without multiblob (the default) must not create the sidecar.
  ifcb_extract_features(data_folder, features_folder, blobs_folder,
                        bins = bin, verbose = FALSE)
  expect_false(file.exists(multiblob_file))

  # Every ROI in the test bin is single-blob, so a multiblob run writes no
  # sidecar either (upstream behaviour: the file exists only for bins that
  # hold multi-blob ROIs). The bin is skipped rather than re-extracted: the
  # numBlobs column of the existing feature CSV says no sidecar is expected.
  result <- ifcb_extract_features(data_folder, features_folder, blobs_folder,
                                  bins = bin, multiblob = TRUE, verbose = FALSE)
  expect_equal(result$status[result$bin == bin], "skipped")
  expect_false(file.exists(multiblob_file))

  # A fresh multiblob extraction of the same single-blob bin also ends
  # without a sidecar, and reports the bin as processed.
  result_over <- ifcb_extract_features(data_folder, features_folder,
                                       blobs_folder, bins = bin,
                                       multiblob = TRUE, overwrite = TRUE,
                                       verbose = FALSE)
  expect_equal(result_over$status[result_over$bin == bin], "processed")
  expect_false(file.exists(multiblob_file))

  # When the feature CSV reports a multi-blob ROI and the sidecar is missing,
  # a multiblob re-run must re-extract the bin without overwrite = TRUE.
  # Fake the expectation by editing numBlobs (the recompute then restores it).
  features <- readr::read_csv(features_file, show_col_types = FALSE)
  features$numBlobs[1] <- 2
  readr::write_csv(features, features_file)
  result_resume <- ifcb_extract_features(data_folder, features_folder,
                                         blobs_folder, bins = bin,
                                         multiblob = TRUE, verbose = FALSE)
  expect_equal(result_resume$status[result_resume$bin == bin], "processed")
  features_after <- readr::read_csv(features_file, show_col_types = FALSE)
  expect_true(all(features_after$numBlobs == 1))
})

test_that("multiblob rows reach the sidecar CSV", {
  # No ROI in the bundled test bin has more than one blob, so the run above
  # only ever writes a header-only sidecar. To exercise the rows-present path,
  # substitute a compute_features that reports two blobs for every ROI and run
  # a single bin through _process_bin.
  skip_if_no_python()
  skip_if_no_ifcb_features()
  skip_on_cran()

  skip_if(Sys.getenv("SKIP_PYTHON_TESTS") == "true",
          "Skipping Python-dependent tests: missing Python packages or running on CRAN.")

  extract <- reticulate::import_from_path(
    "extract_slim_features",
    path = system.file("python", package = "iRfcb"),
    delay_load = FALSE
  )
  skip_if(is.null(extract$BLOB_FEATURE_COLUMNS),
          "Installed ifcb-features predates multiblob output (v1.2.0).")

  real_compute <- reticulate::py_get_attr(extract, "compute_features")
  on.exit(reticulate::py_set_attr(extract, "compute_features", real_compute),
          add = TRUE)
  reticulate::py_run_string(paste(
    "import extract_slim_features as _esf",
    "def _esf_fake_compute(image, _real=_esf.compute_features, _esf=_esf):",
    "    blobs_image, feats, _ = _esf._unpack_compute_features(_real(image))",
    "    rows = [(1, {'Area': 30.0}), (2, {'Area': 12.0})]",
    "    return blobs_image, feats, rows",
    "_esf.compute_features = _esf_fake_compute",
    sep = "\n"
  ))

  temp_dir <- file.path(tempdir(), "ifcb_extract_features_multiblob_rows")
  unzip(test_path("test_data/test_data.zip"), exdir = temp_dir)
  bin <- "D20220522T003051_IFCB134"
  features_folder <- file.path(temp_dir, "features_out")
  blobs_folder <- file.path(temp_dir, "blobs_out")
  # _process_bin expects its output directories to exist (extract_features and
  # ParallelExtractor create them before dispatching bins).
  dir.create(features_folder, recursive = TRUE)
  dir.create(blobs_folder, recursive = TRUE)

  result <- extract$`_process_bin`(
    file.path(temp_dir, "test_data/data"), features_folder, blobs_folder,
    bin, TRUE, "features", NULL, TRUE
  )
  expect_equal(result$status, "processed")

  multiblob <- readr::read_csv(
    file.path(features_folder, "multiblob", paste0(bin, "_multiblob_v4.csv")),
    show_col_types = FALSE
  )
  features <- readr::read_csv(
    file.path(features_folder, paste0(bin, "_features_v4.csv")),
    show_col_types = FALSE
  )

  # Two rows per ROI, blob-numbered 1 and 2, with the supplied Area values in
  # the Area column; per-blob columns the fake rows did not carry are empty
  # rather than misaligned.
  expect_equal(nrow(multiblob), 2 * nrow(features))
  expect_equal(sort(unique(multiblob$blob_number)), c(1, 2))
  expect_equal(unique(multiblob$Area[multiblob$blob_number == 1]), 30)
  expect_equal(unique(multiblob$Area[multiblob$blob_number == 2]), 12)
  expect_true(all(is.na(multiblob$Biovolume)))

  # The sidecar has the upstream layout: roi_number and blob_number followed
  # by the per-blob feature columns.
  expect_equal(names(multiblob)[1:2], c("roi_number", "blob_number"))
  expect_equal(names(multiblob)[-(1:2)],
               unlist(extract$BLOB_FEATURE_COLUMNS))

  # ifcb_read_features() must pick the sidecar up with multiblob = TRUE (it
  # searches recursively and filters on "multiblob" in the file name - this
  # test's directory has "multiblob" in its *path*, guarding the distinction)
  # and keep it out of a default read, which would otherwise mix per-blob
  # rows into per-ROI feature tables.
  read_mb <- ifcb_read_features(features_folder, multiblob = TRUE,
                                verbose = FALSE)
  expect_equal(names(read_mb), paste0(bin, "_multiblob_v4.csv"))
  read_default <- ifcb_read_features(features_folder, verbose = FALSE)
  expect_equal(names(read_default), paste0(bin, "_features_v4.csv"))

  # An existing sidecar makes a further multiblob run skip the bin.
  result_skip <- extract$`_process_bin`(
    file.path(temp_dir, "test_data/data"), features_folder, blobs_folder,
    bin, FALSE, "features", NULL, TRUE
  )
  expect_equal(result_skip$status, "skipped")

  # Re-extracting with the real compute_features finds no multi-blob ROIs and
  # must remove the now-stale sidecar, which would otherwise contradict the
  # fresh feature CSV.
  reticulate::py_set_attr(extract, "compute_features", real_compute)
  result_real <- extract$`_process_bin`(
    file.path(temp_dir, "test_data/data"), features_folder, blobs_folder,
    bin, TRUE, "features", NULL, TRUE
  )
  expect_equal(result_real$status, "processed")
  expect_false(file.exists(file.path(features_folder, "multiblob",
                                     paste0(bin, "_multiblob_v4.csv"))))
})

test_that("multiblob = TRUE aborts on ifcb-features releases older than 1.2.0", {
  skip_if_no_python()
  skip_if_no_ifcb_features()
  skip_on_cran()

  skip_if(Sys.getenv("SKIP_PYTHON_TESTS") == "true",
          "Skipping Python-dependent tests: missing Python packages or running on CRAN.")

  # Simulate a pre-1.2.0 install by blanking the module attribute the version
  # check reads (it is None there because the BLOB_FEATURE_COLUMNS import
  # fails); import_from_path returns the cached module, so ifcb_extract_features
  # sees the same object.
  extract <- reticulate::import_from_path(
    "extract_slim_features",
    path = system.file("python", package = "iRfcb"),
    delay_load = FALSE
  )
  original <- reticulate::py_get_attr(extract, "BLOB_FEATURE_COLUMNS")
  reticulate::py_set_attr(extract, "BLOB_FEATURE_COLUMNS", NULL)
  on.exit(reticulate::py_set_attr(extract, "BLOB_FEATURE_COLUMNS", original),
          add = TRUE)

  temp_dir <- file.path(tempdir(), "ifcb_extract_features_multiblob_guard")
  unzip(test_path("test_data/test_data.zip"), exdir = temp_dir)

  expect_error(
    ifcb_extract_features(file.path(temp_dir, "test_data/data"),
                          file.path(temp_dir, "features_out"),
                          file.path(temp_dir, "blobs_out"),
                          bins = "D20220522T003051_IFCB134",
                          multiblob = TRUE, verbose = FALSE),
    "1\\.2\\.0"
  )
})

test_that("the raw-data reader supports both ifcb-features backends", {
  skip_if_no_python()
  skip_if_no_ifcb_features()
  skip_on_cran()

  skip_if(Sys.getenv("SKIP_PYTHON_TESTS") == "true",
          "Skipping Python-dependent tests: missing Python packages or running on CRAN.")

  reader <- reticulate::import_from_path(
    "ifcb_reader",
    path = system.file("python", package = "iRfcb"),
    delay_load = FALSE
  )

  # At least one backend must be present for the other feature tests to run.
  backends <- reader$available_backends()
  expect_true(length(backends) > 0)
  expect_true(all(backends %in% c("ifcbkit", "pyifcb")))

  # An unknown backend is rejected rather than silently ignored.
  expect_error(reader$open_data_directory(tempdir(), backend = "nonesuch"),
               "Unknown IFCB raw-data backend")

  temp_dir <- file.path(tempdir(), "ifcb_reader_backends")
  unzip(test_path("test_data/test_data.zip"), exdir = temp_dir)
  data_folder <- file.path(temp_dir, "test_data/data")
  bin <- "D20220522T003051_IFCB134"

  # Every available backend must find the test bin and agree on its lid.
  for (backend in backends) {
    dd <- reader$open_data_directory(data_folder, backend = backend)
    expect_equal(dd$backend, backend)
    expect_true(bin %in% dd$list_lids())
  }
})

test_that("ifcb_extract_features validates the backend argument", {
  # Argument validation happens before the Python and data-folder checks, so
  # this needs no Python environment.
  expect_error(
    ifcb_extract_features("nonexistent", "f", "b", backend = "ifcbKit"),
    "should be one of|'arg' should be"
  )
  expect_error(
    ifcb_extract_features("nonexistent", "f", "b", backend = "scipy"),
    "should be one of|'arg' should be"
  )
})

test_that("the backend override is read from R rather than from Python's environment", {
  skip_if_no_python()
  skip_if_no_ifcb_features()
  skip_on_cran()

  # Python captures os.environ when the interpreter starts, so a Sys.setenv()
  # made from R afterwards is invisible to it. iRfcb therefore has to read the
  # variable on the R side and forward it as an argument; assert the premise so
  # this does not silently regress to reading it in Python.
  reticulate::py_run_string("import os")
  old <- Sys.getenv("IRFCB_IFCB_BACKEND", unset = NA)
  on.exit({
    if (is.na(old)) Sys.unsetenv("IRFCB_IFCB_BACKEND") else Sys.setenv(IRFCB_IFCB_BACKEND = old)
  }, add = TRUE)

  Sys.setenv(IRFCB_IFCB_BACKEND = "pyifcb")
  expect_equal(Sys.getenv("IRFCB_IFCB_BACKEND"), "pyifcb")
  expect_null(reticulate::py_eval('os.environ.get("IRFCB_IFCB_BACKEND")'))

  # An unusable value set via the environment must still be rejected, which only
  # happens if R reads it.
  Sys.setenv(IRFCB_IFCB_BACKEND = "not-a-backend")
  expect_error(
    ifcb_extract_features("nonexistent", "f", "b"),
    "should be one of|'arg' should be"
  )
})
