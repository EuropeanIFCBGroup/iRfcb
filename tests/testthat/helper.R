# Helper function to create a temporary .mat file with a named classlist object
create_temp_mat_file <- function(file_path, classlist) {
  R.matlab::writeMat(file_path, classlist = classlist) # Ensure 'classlist' is named
}

# Define the setup function
setup_mock_directory <- function() {
  temp_dir <- tempdir()  # Use tempdir() to create a temporary directory
  test_data_zip <- test_path("test_data/test_data.zip")

  # Unzip the test data into the temporary directory
  unzip(test_data_zip, exdir = temp_dir)

  temp_dir
}

# Helper function to create a temporary ferrybox file with specified content
create_temp_ferrybox_file <- function(file_path, content) {
  writeLines(content, file_path)
}

# Mock wm_records_names to return predefined results
mock_wm_records_names <- function(names, marine_only) {
  records <- list(
    Nitzschia = list(class = "Bacillariophyceae"),
    Chaetoceros = list(class = "Bacillariophyceae"),
    Dinophysis = list(class = "Dinophyceae"),
    Thalassiosira = list(class = "Bacillariophyceae")
  )
  lapply(names, function(name) records[[name]])
}

# Mocking the extract_class function to return the class from the mocked records
mock_extract_class <- function(record) {
  record$class
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
