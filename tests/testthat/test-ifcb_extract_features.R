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
