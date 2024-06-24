#' @importFrom utils flush.console
#' @importFrom stats na.omit
# Function to create MANIFEST.txt
#
# This function generates a MANIFEST.txt file that lists all files in the specified paths,
# along with their sizes. It recursively includes files from directories and skips paths that
# do not exist. The manifest excludes the manifest file itself if present in the list.
#
# @param paths A character vector of paths to files and/or directories to include in the manifest.
# @param manifest_path A character string specifying the path to the manifest file. Default is "MANIFEST.txt".
# @param temp_dir A character string specifying the temporary directory to be removed from the file paths.
create_package_manifest <- function(paths, manifest_path = "MANIFEST.txt", temp_dir) {
  # Initialize a vector to store all files
  all_files <- c()

  # Iterate over each path in the provided list
  for (path in paths) {
    if (dir.exists(path)) {
      # If the path is a directory, list all files in the folder and subfolders
      files <- list.files(path, recursive = TRUE, full.names = TRUE)
    } else if (file.exists(path)) {
      # If the path is a single file, add it to the list
      files <- path
    } else {
      # If the path does not exist, skip it
      next
    }
    # Append the files with their relative paths to the all_files vector
    all_files <- c(all_files, files)
  }

  # Remove any potential duplicates
  all_files <- unique(all_files)

  # Get file sizes
  file_sizes <- file.info(all_files)$size

  # Create a data frame with filenames and their sizes
  manifest_df <- data.frame(
    file = gsub(paste0(temp_dir, "/"), "", all_files, fixed = TRUE),
    size = file_sizes,
    stringsAsFactors = FALSE
  )

  # Format the file information as "filename [size]"
  manifest_content <- paste0(manifest_df$file, " [", formatC(manifest_df$size, format = "d", big.mark = ","), " bytes]")

  # Exclude the manifest file itself if it's already present in the list
  manifest_content <- manifest_content[manifest_df$file != basename(manifest_path)]

  # Write the manifest content to MANIFEST.txt
  writeLines(manifest_content, manifest_path)
}

# Function to truncate the folder name
#
# This function removes the trailing underscore and three digits from the base name of a folder.
#
# @param folder_name A character string specifying the folder name to truncate.
# @return A character string with the truncated folder name.
truncate_folder_name <- function(folder_name) {
  sub("_\\d{3}$", "", basename(folder_name))
}

# Function to print the progress bar
#
# This function prints a progress bar to the console to indicate the progress of a process.
#
# @param current An integer specifying the current progress.
# @param total An integer specifying the total steps for the process.
# @param bar_width An integer specifying the width of the progress bar. Default is 50.
print_progress <- function(current, total, bar_width = 50) {
  progress <- current / total
  complete <- round(progress * bar_width)
  bar <- paste(rep("=", complete), collapse = "")
  remaining <- paste(rep(" ", bar_width - complete), collapse = "")
  cat(sprintf("\r[%s%s] %d%%", bar, remaining, round(progress * 100)))
  flush.console()
}

# Function to find matching feature files with a general pattern
#
# This function finds feature files that match the base name of a given .mat file.
#
# @param mat_file A character string specifying the path to the .mat file.
# @param feature_files A character vector of paths to feature files to search.
# @return A character vector of matching feature files.
find_matching_features <- function(mat_file, feature_files) {
  base_name <- tools::file_path_sans_ext(basename(mat_file))
  matching_files <- grep(base_name, feature_files, value = TRUE)
  return(matching_files)
}

# Function to find matching data files with a general pattern
#
# This function finds data files that match the base name of a given .mat file.
#
# @param mat_file A character string specifying the path to the .mat file.
# @param data_files A character vector of paths to data files to search.
# @return A character vector of matching data files.
find_matching_data <- function(mat_file, data_files) {
  base_name <- tools::file_path_sans_ext(basename(mat_file))
  matching_files <- grep(base_name, data_files, value = TRUE)
  return(matching_files)
}

# Function to read individual files and extract relevant lines
#
# This function reads an HDR file and extracts relevant lines containing parameters and their values.
#
# @param file A character string specifying the path to the HDR file.
# @return A data frame with columns: parameter, value, and file.
read_hdr_file <- function(file) {
  lines <- readLines(file, warn = FALSE)
  data <- do.call(rbind, lapply(lines, function(line) {
    split_line <- strsplit(line, ": ", fixed = TRUE)[[1]]
    if (length(split_line) == 2) {
      return(data.frame(parameter = split_line[1], value = split_line[2], file = file, stringsAsFactors = FALSE))
    }
  }))
  data <- na.omit(data)
  return(data)
}

# Function to extract parts using regular expressions
#
# This function extracts timestamp, IFCB number, and date components from a filename.
#
# @param filename A character string specifying the filename to extract parts from.
# @return A data frame with columns: sample, timestamp, date, year, month, day, time, and ifcb_number.
extract_parts <- function(filename) {

  # Clean filename
  filename <- tools::file_path_sans_ext(filename)

  # Extract timestamp and IFCB number
  timestamp_str <- stringr::str_extract(filename, "D\\d{8}T\\d{6}")
  ifcb_number <- stringr::str_extract(filename, "IFCB\\d+")

  # Extract the ROI part if it exists
  roi_str <- stringr::str_extract(filename, "_\\d+$")
  roi <- ifelse(is.na(roi_str), NA, as.integer(stringr::str_remove(roi_str, "_")))

  # Convert timestamp string to proper datetime format
  full_timestamp <- lubridate::ymd_hms(
    paste0(
      stringr::str_remove_all(timestamp_str, "[^0-9]"), # Remove all non-numeric characters
      collapse = ""
    )
  )

  # Extract date, year, month, day, and time
  date <- lubridate::date(full_timestamp)
  year <- lubridate::year(full_timestamp)
  month <- lubridate::month(full_timestamp)
  day <- lubridate::day(full_timestamp)
  time <- format(full_timestamp, "%H:%M:%S")
  sample <- stringr::str_remove(filename, "_\\d+$")

  df <- data.frame(
    sample = sample,
    timestamp = full_timestamp,
    date = date,
    year = year,
    month = month,
    day = day,
    time = time,
    ifcb_number = ifcb_number,
    stringsAsFactors = FALSE
  )

  # Conditionally add the ROI column if it has no NAs
  if (!any(is.na(roi))) {
    df$roi <- roi
  }
  return(df)
}
#' Install iRfcb Python Environment
#'
#' This function creates a Python virtual environment named "iRfcb" and installs the required Python packages as specified in the "requirements.txt" file.
#'
#' @param ... Additional arguments passed to `virtualenv_create`.
#' @param envname A character string specifying the name of the virtual environment to create. Default is "iRfcb".
#'
#' @examples
#' \dontrun{
#' # Install the iRfcb Python environment
#' ifcb_install_iRfcb()
#' }
#' @import reticulate
#' @export
ifcb_py_install <- function(..., envname = "/.virtualenvs/iRfcb") {
  virtualenv_create(envname, requirements = system.file("python", "requirements.txt", package = "iRfcb"))
}
#' Load iRfcb Python Environment on Package Load
#'
#' This function attempts to use the "iRfcb" Python virtual environment when the package is loaded.
#'virtualenv
#' @param ... Additional arguments passed to the function.
#' @param envname A character string specifying the name of the virtual environment to create. Default is "iRfcb".
.onLoad <- function(..., envname = "/.virtualenvs/iRfcb") {
  use_virtualenv(envname, required = FALSE)
}
