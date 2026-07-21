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
