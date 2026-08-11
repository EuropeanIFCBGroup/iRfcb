# Helper function to create a temporary .mat file with a named classlist object,
# using the package's native MAT writer (no R.matlab dependency).
create_temp_mat_file <- function(file_path, classlist) {
  dir.create(dirname(file_path), showWarnings = FALSE, recursive = TRUE)
  write_mat_v5(file_path, list(classlist = mat_var_double(classlist)))
}

# Define the setup function
setup_mock_directory <- function() {
  temp_dir <- file.path(tempdir(), "mock_dir")  # Use tempdir() to create a temporary directory
  test_data_zip <- test_path("test_data/test_data.zip")

  # Unzip the test data into the temporary directory
  unzip(test_data_zip, exdir = temp_dir)

  temp_dir
}

# Helper function to create a temporary ferrybox file with specified content
create_temp_ferrybox_file <- function(file_path, content) {
  writeLines(content, file_path)
}

# Mock the helper function to simulate WoRMS data retrieval
mocked_worms_records <- function(taxa_names, max_retries = 3, sleep_time = 10, marine_only = FALSE, return_list = FALSE, verbose = FALSE) {
  # Simulated data
  records <- list(
    list(scientificname = "Nitzschia", class = "Bacillariophyceae"),
    list(scientificname = "Chaetoceros", class = "Bacillariophyceae"),
    list(scientificname = "Dinophysis", class = "Dinophyceae"),
    list(scientificname = "Thalassiosira", class = "Bacillariophyceae")
  )

  records[match(taxa_names, sapply(records, function(x) x$scientificname))]
}

mocked_extract_class <- function(record) {
  record$class
}

# Mock wm_records_names to simulate an error
mocked_wm_records_names_error <- function(taxa_names, marine_only = FALSE, return_list = FALSE) {
  stop("Simulated retrieval error")
}

# Mock feature files creation
setup_test_files <- function(base_path) {
  if (!dir.exists(base_path)) {
    dir.create(base_path, recursive = TRUE)
  }

  # Create mock CSV files
  write.csv(data.frame(roi_number = 1:5, Biovolume = 6:10, A = 11:15, B = 16:20), file = file.path(base_path, "D20230316T101514_fea_v2.csv"), row.names = FALSE)
  write.csv(data.frame(roi_number = 1:5, Biovolume = 6:10, C = 11:15, D = 16:20), file = file.path(base_path, "D20230316T101515_multiblob_fea_v2.csv"), row.names = FALSE)
  write.csv(data.frame(roi_number = 1:5, Biovolume = 6:10, E = 11:15, F = 16:20), file = file.path(base_path, "D20230316T101516_fea_v2.csv"), row.names = FALSE)
}

# Remove mock feature files after tests
cleanup_test_files <- function(base_path) {
  unlink(base_path, recursive = TRUE)
}

# Helper function to create a temporary HDR file from the package example
create_temp_hdr_from_example <- function(exdir, hdr_file_path) {
  hdr_folder <- file.path(exdir, "temp")
  if (!dir.exists(hdr_folder)) {
    dir.create(hdr_folder)
  }
  file.copy(hdr_file_path, file.path(hdr_folder, "D20230314T001205_IFCB134.hdr"))
  hdr_folder
}

# Cache for Python package availability (avoids repeated slow py_list_packages calls)
.py_pkg_cache <- new.env(parent = emptyenv())

.check_py_package <- function(pkg) {
  # Skip early on CRAN — no Python venv is created there
  if (!identical(Sys.getenv("NOT_CRAN"), "true")) {
    testthat::skip(paste(pkg, "not available for testing (CRAN)"))
  }
  # Return cached result if available
  if (!is.null(.py_pkg_cache[[pkg]])) {
    if (!.py_pkg_cache[[pkg]]) testthat::skip(paste(pkg, "not available for testing"))
    return(invisible(TRUE))
  }
  # Perform the check once and cache
  if (!reticulate::py_available(initialize = TRUE)) {
    .py_pkg_cache[[pkg]] <- FALSE
    testthat::skip(paste(pkg, "not available for testing"))
  }
  # Probe the import, exactly as the code under test does (scipy_available()).
  # py_list_packages() asks the environment manager instead, and on a conda
  # environment that listing can omit an installed, importable module - which
  # would skip every scipy test on precisely the setup the 0.10.0 probe fix
  # targets.
  .py_pkg_cache[[pkg]] <- isTRUE(tryCatch(reticulate::py_module_available(pkg),
                                          error = function(e) FALSE))
  if (!.py_pkg_cache[[pkg]])
    testthat::skip(paste(pkg, "not available for testing"))
}

skip_if_no_scipy <- function() {
  .check_py_package("scipy")
}

skip_if_no_matplotlib <- function() {
  .check_py_package("matplotlib")
}

skip_if_no_pandas <- function() {
  .check_py_package("pandas")
}

skip_if_no_ifcb_features <- function() {
  # ifcb-features is installed from GitHub (VCS), which py_list_packages() may
  # not report, so check the importable module names instead.
  if (!identical(Sys.getenv("NOT_CRAN"), "true")) {
    testthat::skip("ifcb-features not available for testing (CRAN)")
  }
  if (!reticulate::py_available(initialize = TRUE)) {
    testthat::skip("Python not available for testing")
  }
  # The raw-data reader is 'ifcbkit' for ifcb-features >= 1.1.0 and 'ifcb'
  # (pyifcb) for earlier releases; either is enough to run the tests.
  has_reader <- reticulate::py_module_available("ifcbkit") ||
    reticulate::py_module_available("ifcb")

  if (!reticulate::py_module_available("ifcb_features") || !has_reader) {
    testthat::skip("ifcb-features not available for testing")
  }
}

skip_if_no_python <- function() {
  if (!identical(Sys.getenv("NOT_CRAN"), "true")) {
    testthat::skip("Python not available for testing (CRAN)")
  }
  if (!reticulate::py_available(initialize = TRUE))
    testthat::skip("Python not available for testing")
}

# Skip test if a remote resource is not responding (HTTP errors included)
skip_if_resource_unavailable <- function(url, msg = NULL) {
  ok <- tryCatch({
    res <- curl::curl_fetch_memory(url)
    status <- res$status_code

    # Treat 2xx and 405 (Method Not Allowed) as available;
    # 405 means the server is alive but the endpoint requires POST
    (status >= 200 && status < 300) || status == 405
  }, error = function(e) FALSE)

  if (!ok) {
    if (is.null(msg)) {
      msg <- paste("Resource not responding or returned non-2xx status:", url)
    }
    testthat::skip(msg)
  }
}
