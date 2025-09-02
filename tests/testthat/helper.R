# Helper function to create a temporary .mat file with a named classlist object
create_temp_mat_file <- function(file_path, classlist) {
  R.matlab::writeMat(file_path, classlist = classlist) # Ensure 'classlist' is named
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
  write.csv(data.frame(A = 1:5, B = 6:10), file = file.path(base_path, "D20230316T101514.csv"), row.names = FALSE)
  write.csv(data.frame(C = 1:5, D = 6:10), file = file.path(base_path, "D20230316T101515_multiblob.csv"), row.names = FALSE)
  write.csv(data.frame(E = 1:5, F = 6:10), file = file.path(base_path, "D20230316T101516.csv"), row.names = FALSE)
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

# Mock the Python function (replace_value_in_classlist)
mock_replace_value_in_classlist <- function(input_file, output_file, target_value, new_value, column_index) {
  # Read the input .mat file
  mat_contents <- R.matlab::readMat(input_file)
  classlist <- mat_contents$classlist

  # Replace target_value with new_value in the specified column
  mask <- classlist[, column_index + 1] == target_value # Adjust for 1-based indexing in R
  classlist[mask, column_index + 1] <- new_value

  # Write the modified contents to the output .mat file
  R.matlab::writeMat(output_file, classlist = classlist)
}

skip_if_no_scipy <- function() {
  reticulate::py_available(initialize = TRUE)
  available_packages <- reticulate::py_list_packages(python = reticulate::py_discover_config()$python)
  if (!"scipy" %in% available_packages$package)
    skip("scipy not available for testing")
}

skip_if_no_matplotlib <- function() {
  reticulate::py_available(initialize = TRUE)
  available_packages <- reticulate::py_list_packages(python = reticulate::py_discover_config()$python)
  if (!"matplotlib" %in% available_packages$package)
    skip("matplotlib not available for testing")
}

skip_if_no_pandas <- function() {
  reticulate::py_available(initialize = TRUE)
  available_packages <- reticulate::py_list_packages(python = reticulate::py_discover_config()$python)
  if (!"pandas" %in% available_packages$package)
    skip("pandas not available for testing")
}

skip_if_no_python <- function() {
    if (!reticulate::py_available(initialize = TRUE))
    skip("Python not available for testing")
}

# Skip test if a remote resource is not responding
skip_if_resource_unavailable <- function(url, msg = NULL) {
  ok <- tryCatch({
    curl::curl_fetch_memory(url)
    TRUE
  }, error = function(e) FALSE)

  if (!ok) {
    if (is.null(msg)) {
      msg <- paste("Resource not responding:", url)
    }
    testthat::skip(msg)
  }
}
