utils::globalVariables(":=")
#' Function to Create MANIFEST.txt
#'
#' This function generates a MANIFEST.txt file that lists all files in the specified paths,
#' along with their sizes. It recursively includes files from directories and skips paths that
#' do not exist. The manifest excludes the manifest file itself if present in the list.
#'
#' @param paths A character vector of paths to files and/or directories to include in the manifest.
#' @param manifest_path A character string specifying the path to the manifest file. Default is "MANIFEST.txt".
#' @param temp_dir A character string specifying the temporary directory to be removed from the file paths.
#' @return This function does not return any value. It creates a `MANIFEST.txt` file at the specified location,
#'         which contains a list of all files (including their sizes) in the provided paths.
#'         The file paths are relative to the specified `temp_dir`, and the manifest excludes the manifest file itself if present.
#' @export
create_package_manifest <- function(paths, manifest_path = "MANIFEST.txt", temp_dir) {
  # Initialize a vector to store all files
  all_files <- NULL

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

#' Function to Truncate the Folder Name
#'
#' This function removes the trailing underscore and three digits from the base name of a folder.
#'
#' @param folder_name A character string specifying the folder name to truncate.
#' @return A character string with the truncated folder name.
#' @noRd
truncate_folder_name <- function(folder_name) {
  sub("_\\d{3}$", "", basename(folder_name))
}

#' Function to Print the Progress Bar
#'
#' This function prints a progress bar to the console to indicate the progress of a process.
#'
#' @param current An integer specifying the current progress.
#' @param total An integer specifying the total steps for the process.
#' @param bar_width An integer specifying the width of the progress bar. Default is 50.
#' @noRd
print_progress <- function(current, total, bar_width = 50) {
  progress <- current / total
  complete <- round(progress * bar_width)
  bar <- paste(rep("=", complete), collapse = "")
  remaining <- paste(rep(" ", bar_width - complete), collapse = "")
  cat(sprintf("\r[%s%s] %d%%", bar, remaining, round(progress * 100)))
  flush.console()
}

#' Function to Find Matching Feature Files with a General Pattern
#'
#' This function finds feature files that match the base name of a given .mat file.
#'
#' @param mat_file A character string specifying the path to the .mat file.
#' @param feature_files A character vector of paths to feature files to search.
#' @return A character vector of matching feature files.
#' @noRd
find_matching_features <- function(mat_file, feature_files) {
  base_name <- tools::file_path_sans_ext(basename(mat_file))
  matching_files <- grep(base_name, feature_files, value = TRUE)
  matching_files
}

#' Function to Find Matching Data Files with a General Pattern
#'
#' This function finds data files that match the base name of a given .mat file.
#'
#' @param mat_file A character string specifying the path to the .mat file.
#' @param data_files A character vector of paths to data files to search.
#' @return A character vector of matching data files.
#' @noRd
find_matching_data <- function(mat_file, data_files) {
  base_name <- tools::file_path_sans_ext(basename(mat_file))
  matching_files <- grep(base_name, data_files, value = TRUE)
  matching_files
}

#' Function to Read Individual Files and Extract Relevant Lines
#'
#' This function reads an HDR file and extracts relevant lines containing parameters and their values.
#'
#' @param file A character string specifying the path to the HDR file.
#' @return A data frame with columns: parameter, value, and file.
#' @export
read_hdr_file <- function(file) {
  lines <- readLines(file, warn = FALSE)
  lines <- gsub("\\bN/A\\b", NA, lines)

  data <- do.call(rbind, lapply(lines, function(line) {
    split_line <- strsplit(line, ": ", fixed = TRUE)[[1]]
    if (length(split_line) == 2) {
      data.frame(parameter = split_line[1], value = split_line[2], file = file, stringsAsFactors = FALSE)
    }
  }))
  data <- na.omit(data)
  data
}

#' Function to Extract Parts Using Regular Expressions
#'
#' This function extracts timestamp, IFCB number, and date components from a filename.
#'
#' @param filename A character string specifying the filename to extract parts from.
#' @return A data frame with columns: sample, timestamp, date, year, month, day, time, and ifcb_number.
#' @noRd
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
  df
}

#' Summarize TreeBagger Classifier Results
#'
#' This function reads a TreeBagger classifier result file (.mat format) and summarizes
#' the number of targets in each class based on the classification scores and thresholds.
#'
#' @param classfile Character string specifying the path to the TreeBagger classifier result file (.mat format).
#' @param adhocthresh Numeric vector specifying the adhoc thresholds for each class. If NULL (default), no adhoc thresholding is applied.
#'                    If a single numeric value is provided, it is applied to all classes.
#'
#' @return A list containing three elements:
#'   \item{classcount}{Numeric vector of counts for each class based on the winning class assignment.}
#'   \item{classcount_above_optthresh}{Numeric vector of counts for each class above the optimal threshold for maximum accuracy.}
#'   \item{classcount_above_adhocthresh}{Numeric vector of counts for each class above the specified adhoc thresholds (if provided).}
#' @export
summarize_TBclass <- function(classfile, adhocthresh = NULL) {
  data <- readMat(classfile, fixNames = FALSE)
  class2useTB <- data$class2useTB
  TBscores <- data$TBscores
  TBclass <- data$TBclass
  TBclass_above_threshold <- data$TBclass_above_threshold

  classcount <- rep(NA, length(class2useTB))
  classcount_above_optthresh <- classcount
  classcount_above_adhocthresh <- classcount

  if (!is.null(adhocthresh)) {
    if (length(adhocthresh) == 1) {
      adhocthresh <- rep(adhocthresh, length(class2useTB))
    }
  }

  maxscore <- apply(TBscores, 1, max)
  winclass <- apply(TBscores, 1, which.max)

  for (ii in seq_along(class2useTB)) {
    classcount[ii] <- sum(unlist(TBclass) == class2useTB[[ii]])
    classcount_above_optthresh[ii] <- sum(unlist(TBclass_above_threshold) == class2useTB[[ii]])

    if (!is.null(adhocthresh)) {
      ind <- unlist(TBclass) == class2useTB[[ii]] & maxscore >= adhocthresh[ii]
      classcount_above_adhocthresh[ii] <- sum(ind)
    }
  }

  list(classcount, classcount_above_optthresh, classcount_above_adhocthresh)
}
#' Convert Biovolume to Carbon for Large Diatoms
#'
#' This function converts biovolume in microns^3 to carbon in picograms
#' for large diatoms (> 2000 micron^3) according to Menden-Deuer and Lessard 2000.
#' The formula used is: log pgC cell^-1 = log a + b * log V (um^3),
#' with log a = -0.933 and b = 0.881 for diatoms > 3000 um^3.
#'
#' @param volume A numeric vector of biovolume measurements in microns^3.
#'
#' @return A numeric vector of carbon measurements in picograms.
#'
#' @examples
#' # Volumes in microns^3
#' volume <- c(5000, 10000, 20000)
#'
#' # Convert biovolume to carbon for large diatoms
#' vol2C_lgdiatom(volume)
#' @export
vol2C_lgdiatom <- function(volume) {
  loga <- -0.933
  b <- 0.881
  logC <- loga + b * log10(volume)
  carbon <- 10^logC
  carbon
}
#' Convert Biovolume to Carbon for Non-Diatom Protists
#'
#' This function converts biovolume in microns^3 to carbon in picograms
#' for protists besides large diatoms (> 3000 micron^3) according to Menden-Deuer and Lessard 2000.
#' The formula used is: log pgC cell^-1 = log a + b * log V (um^3),
#' with log a = -0.665 and b = 0.939.
#'
#' @param volume A numeric vector of biovolume measurements in microns^3.
#'
#' @return A numeric vector of carbon measurements in picograms.
#'
#' @examples
#' # Volumes in microns^3
#' volume <- c(5000, 10000, 20000)
#'
#' # Convert biovolume to carbon for non-diatom protists
#' vol2C_nondiatom(volume)
#' @export
vol2C_nondiatom <- function(volume) {
  loga <- -0.665
  b <- 0.939
  logC <- loga + b * log10(volume)
  carbon <- 10^logC
  carbon
}

#' Handle Missing Ferrybox Data
#'
#' This function processes a dataset by filling in missing values for specific parameters using data from a Ferrybox dataset. It rounds the timestamp to a specified unit, joins the Ferrybox data based on the rounded timestamp, and fills in missing values using the corresponding Ferrybox data.
#'
#' @param data A data frame containing the main dataset with a `timestamp` column and several parameter columns that might have missing data.
#' @param ferrybox_data A data frame containing the Ferrybox dataset. This dataset should have a `timestamp` column and columns corresponding to the parameters specified.
#' @param parameters A character vector of column names (parameters) in `data` that should be checked for missing values and potentially filled using the Ferrybox data.
#' @param rounding_function A function that rounds the `timestamp` to a specified unit (e.g., minute). This function should take a `timestamp` column and a `unit` argument.
#'
#' @return A data frame similar to `data`, but with missing values in the specified parameters filled in using the Ferrybox data. The output includes only the `timestamp` and the specified parameter columns.
#'
#' @details
#' The function performs the following steps:
#' \itemize{
#'   \item Renames the columns in the `ferrybox_data` by appending `_ferrybox` to the names of the specified parameters.
#'   \item Filters the `data` for rows with missing values in any of the specified parameters.
#'   \item Rounds the `timestamp` to the nearest specified unit using the `rounding_function`.
#'   \item Joins the `ferrybox_data` to the main `data` based on the rounded `timestamp`.
#'   \item Uses the `coalesce` function to fill in missing values in the specified parameters with the corresponding values from the Ferrybox data.
#'   \item Returns a cleaned dataset containing only the `timestamp` and the specified parameter columns.
#' }
#'
#' @examples
#' \dontrun{
#' # Assuming you have a data frame `data` with missing values, a Ferrybox data frame `ferrybox_data`,
#' # and a rounding function `round_timestamp`.
#' filled_data <- handle_missing_ferrybox_data(data,
#'                                             ferrybox_data,
#'                                             c("8002", "8003", "8172"),
#'                                             round_timestamp)
#' }
#' @noRd
handle_missing_ferrybox_data <- function(data, ferrybox_data, parameters, rounding_function) {
  # Ensure that the columns from ferrybox_data are present and rename them
  ferrybox_data <- ferrybox_data %>%
    dplyr::rename_with(~ paste0(.x, "_ferrybox"), all_of(parameters))

  # Filter rows with missing data for any of the parameters
  missing_data <- data %>%
    filter(if_any(all_of(parameters), is.na)) %>%
    mutate(timestamp_minute = rounding_function(timestamp, unit = "minute")) %>%
    left_join(ferrybox_data, by = "timestamp_minute") %>%
    # Use coalesce to fill missing parameter values
    mutate(across(all_of(parameters), ~ coalesce(.x, get(paste0(cur_column(), "_ferrybox"))))) %>%
    select(timestamp, all_of(parameters))

  missing_data
}
#' Retrieve WoRMS Records with Retry Mechanism
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' This helper function was deprecated as it has been replaced by a main function: \code{ifcb_match_taxon_name}.
#'
#' This helper function attempts to retrieve WoRMS records using the provided taxa names.
#' It retries the operation if an error occurs, up to a specified number of attempts.
#'
#' @param taxa_names A character vector of taxa names to retrieve records for.
#' @param max_retries An integer specifying the maximum number of attempts to retrieve records.
#' @param sleep_time A numeric value indicating the number of seconds to wait between retry attempts.
#' @param marine_only Logical. If TRUE, restricts the search to marine taxa only. Default is FALSE.
#' @param verbose A logical indicating whether to print progress messages. Default is TRUE.
#'
#' @return A list of WoRMS records or NULL if the retrieval fails after the maximum number of attempts.
#'
#' @keywords internal
#' @export
retrieve_worms_records <- function(taxa_names, max_retries = 3, sleep_time = 10, marine_only = FALSE, verbose = TRUE) {

  # Print deprecation warning
  lifecycle::deprecate_warn("0.4.0", "iRfcb::retrieve_worms_records()", "ifcb_match_taxa_names()")

  # Redirect function
  ifcb_match_taxa_names(taxa_names = taxa_names, max_retries = max_retries, sleep_time = sleep_time, return_list = TRUE, marine_only = marine_only, verbose = verbose)
}

#' Extract Features and Add Sample Names
#'
#' This helper function adds the sample name as a column in the feature dataframe.
#' It assumes that the sample name is embedded in the filename, and this function strips unnecessary parts of the filename.
#'
#' @param sample_name Character. The name of the sample, typically derived from the feature file name.
#' @param feature_data Dataframe. The feature data associated with the sample.
#'
#' @return A dataframe with the sample name added as a column.
#'
#' @examples
#' \dontrun{
#' sample_name <- "sample_001_fea_v2.csv"
#' feature_data <- data.frame(roi_number = 1:10, feature_value = rnorm(10))
#' result <- extract_features(sample_name, feature_data)
#' }
#' @noRd
extract_features <- function(sample_name, feature_data) {
  feature_data$sample <- gsub("_fea_v2.csv", "", sample_name)
  feature_data
}

#' Split Large Zip File into Smaller Parts
#'
#' This helper function takes an existing zip file, extracts its contents,
#' and splits it into smaller zip files without splitting subfolders.
#'
#' @param zip_file The path to the large zip file.
#' @param max_size The maximum size (in MB) for each split zip file. Default is 500 MB.
#' @param quiet Logical. If TRUE, suppresses messages about the progress and completion of the zip process. Default is FALSE.
#'
#' @return This function does not return any value; it creates multiple smaller zip files.
#'
#' @examples
#' \dontrun{
#' # Split an existing zip file into parts of up to 500 MB
#' split_large_zip("large_file.zip", max_size = 500)
#' }
#' @export
split_large_zip <- function(zip_file, max_size = 500, quiet = FALSE) {

  # Convert zip_file to an absolute path
  zip_file <- normalizePath(zip_file, winslash = "/")

  # Check if the zip file exists
  if (!file.exists(zip_file)) {
    stop("The specified zip file does not exist")
  }

  # Check the size of the zip file
  zip_file_size <- file.info(zip_file)$size

  # Convert max_size to bytes
  max_size_bytes <- max_size * 1024 * 1024  # Convert MB to bytes

  # Step 0: Check if the zip file is smaller than max_size
  if (zip_file_size <= max_size_bytes) {
    if (!quiet) {
      cat("The zip file is already smaller than the specified max size (", max_size, " MB).\n", sep = "")
    }
    return(invisible(NULL))
  }

  # Step 1: Unzip the large file
  unzip_dir <- file.path(tempdir(), "split_zip_temp")
  dir.create(unzip_dir, showWarnings = FALSE)
  unzip(zip_file, exdir = unzip_dir)

  # Step 2: Get list of subfolders and their sizes
  subfolder_info <- list.dirs(unzip_dir, recursive = TRUE, full.names = TRUE)

  # Exclude the root directory to prevent including all files
  root_dir <- normalizePath(unzip_dir, winslash = "/")
  subfolder_info <- normalizePath(subfolder_info, winslash = "/")  # Normalize paths to use forward slashes
  subfolder_info <- subfolder_info[subfolder_info != root_dir]

  # Now, get the files and sizes for each subfolder
  subfolder_files <- lapply(subfolder_info, function(folder) {
    list.files(folder, recursive = TRUE, full.names = TRUE)
  })

  subfolder_sizes <- sapply(subfolder_files, function(files) {
    sum(file.info(files)$size)
  })

  # Step 3: Remove the base directory (with drive letter) from the paths
  strip_drive_letter <- function(paths, base_dir) {
    # Ensure base_dir is normalized with forward slashes
    base_dir <- normalizePath(base_dir, winslash = "/")

    # Normalize the file paths to use forward slashes
    normalized_paths <- normalizePath(paths, winslash = "/")

    # Remove the base directory from each path, leaving the relative path
    relative_paths <- sub(paste0("^", base_dir, "/"), "", normalized_paths)

    relative_paths
  }

  base_dir <- normalizePath(unzip_dir, winslash = "/")
  relative_subfolder_files <- lapply(subfolder_files, function(files) {
    strip_drive_letter(files, base_dir)
  })

  # Step 4: Group subfolders into zip files without splitting them
  group_subfolders_into_zips <- function(subfolder_files, subfolder_sizes, max_size) {
    groups <- list()
    current_group <- list()
    current_size <- 0

    for (i in seq_along(subfolder_files)) {
      # Check if adding the current subfolder will exceed the size limit
      if (current_size + subfolder_sizes[i] > max_size && current_size > 0) {
        # Save the current group and start a new one
        groups[[length(groups) + 1]] <- current_group
        current_group <- list()
        current_size <- 0
      }

      # Add the current subfolder to the group
      current_group <- c(current_group, subfolder_files[[i]])
      current_size <- current_size + subfolder_sizes[i]
    }

    # Add the last group if it contains any subfolders
    if (length(current_group) > 0) {
      groups[[length(groups) + 1]] <- current_group
    }

    groups
  }

  # Step 5: Set max zip size and group subfolders
  max_zip_size <- 500 * 1024 * 1024  # 500 MB in bytes
  subfolder_groups <- group_subfolders_into_zips(relative_subfolder_files, subfolder_sizes, max_zip_size)


  # Vector to store the names of the created zip files
  created_zip_files <- character()

  # Step 6: Create smaller zip files with grouped subfolders
  for (i in seq_along(subfolder_groups)) {
    zipfile_name <- paste0(tools::file_path_sans_ext(zip_file), "_part_", i, ".zip")

    # Flatten the list of files for the current group
    files_to_zip <- unlist(subfolder_groups[[i]])

    # Zip the group into a new zip file
    zip::zip(zipfile_name, files = files_to_zip, root = root_dir)

    # Add the created zipfile to the list
    created_zip_files <- c(created_zip_files, zipfile_name)
  }

  unlink(unzip_dir, recursive = TRUE)

  if (!quiet) {
    cat("Successfully created", length(subfolder_groups), "smaller zip files:\n")
    cat(paste(created_zip_files, collapse = "\n"), "\n")
  }
}
#' Check Python and Required Modules Availability
#'
#' This helper function checks if Python is available and if the required Python module (e.g., `scipy`) is installed.
#' It stops execution and raises an error if Python or the specified module is not available.
#'
#' @param module Character. Name of the Python module to check (default is "scipy").
#' @param initialize Logical. Whether to initialize Python if not already initialized (default is TRUE).
#'
#' @return This function does not return a value. It stops execution if the required Python environment is not available.
#'
#' @examples
#' \dontrun{
#' check_python_and_module("scipy") # Check for Python and 'scipy'
#' }
#' @noRd
check_python_and_module <- function(module = "scipy", initialize = FALSE) {
  # Check if Python is available
  if (!py_available(initialize = initialize)) {
    stop("Python is not available. Please ensure Python is installed and initalized, or see `ifcb_py_install`.")
  }

  # List available packages
  available_packages <- py_list_packages(python = reticulate::py_discover_config()$python)

  # Check if the required Python module is available
  if (!module %in% available_packages$package) {
    stop(paste("Python package '", module, "' is not available. Please install '", module, "' in your Python environment, or see `ifcb_py_install`.", sep = ""))
  }
}
#' Check Python and SciPy Availability
#'
#' This helper function verifies whether Python is available and if the specified Python module (e.g., `scipy`) is installed.
#'
#' @param initialize Logical. If `TRUE`, attempts to initialize Python if it is not already initialized. Default is `TRUE`.
#'
#' @return Logical. Returns `TRUE` if Python and the specified module are available, otherwise `FALSE`.
#'
#' @examples
#' \dontrun{
#' scipy_available() # Check for Python and 'scipy'
#' }
#' @noRd
scipy_available <- function(initialize = FALSE) {
  # Check if Python is available
  if (!reticulate::py_available(initialize = initialize)) {
    return(FALSE)
  }

  # Get the list of installed Python packages
  available_packages <- reticulate::py_list_packages()

  # Check if 'scipy' is installed
  return("scipy" %in% available_packages$package)
}

#' Install Missing Python Packages
#'
#' A helper function to check for missing Python packages and install them using `reticulate`.
#' If an environment name is provided, the packages are installed in that virtual environment.
#'
#' @param packages Character vector. Names of the Python packages to check and install if missing.
#' @param envname Character (optional). Name of the virtual environment where packages should be installed.
#'   If `NULL`, packages are installed globally.
#' @return Invisibly returns `NULL`. Prints messages about installation status.
#' @noRd
install_missing_packages <- function(packages, envname = NULL) {
  installed <- reticulate::py_list_packages()$package
  missing_packages <- setdiff(packages, installed)

  if (length(missing_packages) > 0) {
    message("Installing missing Python packages: ", paste(missing_packages, collapse = ", "))

    if (is.null(envname)) {
      # Install globally if system Python is used
      reticulate::py_install(missing_packages, pip = TRUE)
    } else {
      # Install in virtual environment
      reticulate::virtualenv_install(envname, missing_packages, ignore_installed = TRUE)
    }
  } else {
    message("All requested packages are already installed.")
  }
}
#' Read MATLAB (.mat) Files
#'
#' A helper function to read MATLAB `.mat` files using the `R.matlab` package.
#' Optionally, it can fix variable names during import.
#'
#' @param file_path Character. Path to the `.mat` file.
#' @param fixNames Logical. If `TRUE`, fixes variable names to be valid R identifiers. Default is `FALSE`.
#' @return A list containing the data from the `.mat` file, with any nested lists converted to character vectors.
#' @noRd
read_mat <- function(file_path, fixNames = FALSE) {
  # Read the contents of the MAT file
  mat_contents <- suppressWarnings({R.matlab::readMat(file_path, fixNames = fixNames)})

  # Iterate through each element of mat_data2 and convert any list to a character vector
  mat_contents_converted <- lapply(mat_contents, function(x) {
    # Check if the element is a list
    if (is.list(x)) {
      # Flatten the list and convert it to a character vector
      as.character(unlist(x))
    } else {
      # If it's not a list, leave it unchanged
      x
    }
  })
  mat_contents_converted
}
#' Extract the Class from the First Row of Each worms_records Tibble
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' This helper function was deprecated as it has been replaced by a main function: \code{ifcb_match_taxon_name}.
#'
#' This function extracts the class from the first row of a given worms_records tibble.
#' If the tibble is empty, it returns NA.
#'
#' @param record A tibble containing worms_records with at least a 'class' column.
#' @return A character string representing the class of the first row in the tibble,
#' or NA if the tibble is empty.
#' @examples
#' # Example usage:
#' record <- dplyr::tibble(class = c("Class1", "Class2"))
#' iRfcb:::extract_class(record)
#'
#' empty_record <- dplyr::tibble(class = character(0))
#' iRfcb:::extract_class(empty_record)
#' @noRd
extract_class <- function(record) {

  # Print deprecation warning
  lifecycle::deprecate_warn("0.4.3", "iRfcb::extract_class()", "ifcb_match_taxa_names()", "ifcb_match_taxa_names() now returns worms data as data frame")

  if (nrow(record) == 0) {
    NA
  } else {
    record$class[1]
  }
}

#' Extract the AphiaID from the First Row of Each worms_records Tibble
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' This helper function was deprecated as it has been replaced by a main function: \code{ifcb_match_taxon_name}.
#'
#' This function extracts the AphiaID from the first row of a given worms_records tibble.
#' If the tibble is empty, it returns NA.
#'
#' @param record A tibble containing worms_records with at least an 'AphiaID' column.
#' @return A numeric value representing the AphiaID of the first row in the tibble,
#' or NA if the tibble is empty.
#' @examples
#' # Example usage:
#' record <- dplyr::tibble(AphiaID = c(12345, 67890))
#' iRfcb:::extract_aphia_id(record)
#'
#' empty_record <- dplyr::tibble(AphiaID = numeric(0))
#' iRfcb:::extract_aphia_id(empty_record)
#' @noRd
extract_aphia_id <- function(record) {

  # Print deprecation warning
  lifecycle::deprecate_warn("0.4.3", "iRfcb::extract_aphia_id()", "ifcb_match_taxa_names()", "ifcb_match_taxa_names() now returns worms data as data frame")

  if (nrow(record) == 0) {
    NA
  } else {
    record$AphiaID[1]
  }
}
