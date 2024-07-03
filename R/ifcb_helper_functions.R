utils::globalVariables(c("ferrybox_position", ":="))
#' Function to create MANIFEST.txt
#'
#' This function generates a MANIFEST.txt file that lists all files in the specified paths,
#' along with their sizes. It recursively includes files from directories and skips paths that
#' do not exist. The manifest excludes the manifest file itself if present in the list.
#'
#' @param paths A character vector of paths to files and/or directories to include in the manifest.
#' @param manifest_path A character string specifying the path to the manifest file. Default is "MANIFEST.txt".
#' @param temp_dir A character string specifying the temporary directory to be removed from the file paths.
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

#' Function to truncate the folder name
#'
#' This function removes the trailing underscore and three digits from the base name of a folder.
#'
#' @param folder_name A character string specifying the folder name to truncate.
#' @return A character string with the truncated folder name.
truncate_folder_name <- function(folder_name) {
  sub("_\\d{3}$", "", basename(folder_name))
}

#' Function to print the progress bar
#'
#' This function prints a progress bar to the console to indicate the progress of a process.
#'
#' @param current An integer specifying the current progress.
#' @param total An integer specifying the total steps for the process.
#' @param bar_width An integer specifying the width of the progress bar. Default is 50.
#' @importFrom utils flush.console
print_progress <- function(current, total, bar_width = 50) {
  progress <- current / total
  complete <- round(progress * bar_width)
  bar <- paste(rep("=", complete), collapse = "")
  remaining <- paste(rep(" ", bar_width - complete), collapse = "")
  cat(sprintf("\r[%s%s] %d%%", bar, remaining, round(progress * 100)))
  flush.console()
}

#' Function to find matching feature files with a general pattern
#'
#' This function finds feature files that match the base name of a given .mat file.
#'
#' @param mat_file A character string specifying the path to the .mat file.
#' @param feature_files A character vector of paths to feature files to search.
#' @return A character vector of matching feature files.
find_matching_features <- function(mat_file, feature_files) {
  base_name <- tools::file_path_sans_ext(basename(mat_file))
  matching_files <- grep(base_name, feature_files, value = TRUE)
  return(matching_files)
}

#' Function to find matching data files with a general pattern
#'
#' This function finds data files that match the base name of a given .mat file.
#'
#' @param mat_file A character string specifying the path to the .mat file.
#' @param data_files A character vector of paths to data files to search.
#' @return A character vector of matching data files.
find_matching_data <- function(mat_file, data_files) {
  base_name <- tools::file_path_sans_ext(basename(mat_file))
  matching_files <- grep(base_name, data_files, value = TRUE)
  return(matching_files)
}

#' Function to read individual files and extract relevant lines
#'
#' This function reads an HDR file and extracts relevant lines containing parameters and their values.
#'
#' @param file A character string specifying the path to the HDR file.
#' @return A data frame with columns: parameter, value, and file.
#' @importFrom stats na.omit
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

#' Function to extract parts using regular expressions
#'
#' This function extracts timestamp, IFCB number, and date components from a filename.
#'
#' @param filename A character string specifying the filename to extract parts from.
#' @return A data frame with columns: sample, timestamp, date, year, month, day, time, and ifcb_number.
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
#' Load iRfcb Python Environment on Package Load
#'
#' This function attempts to use the "iRfcb" Python virtual environment when the package is loaded.
#'virtualenv
#' @param ... Additional arguments passed to the function.
#' @param envname A character string specifying the name of the virtual environment to create. Default is "iRfcb".
.onLoad <- function(..., envname = "/.virtualenvs/iRfcb") {
  use_virtualenv(envname, required = FALSE)
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
#' @importFrom R.matlab readMat
summarize_TBclass <- function(classfile, adhocthresh = NULL) {
  data <- readMat(classfile)
  class2useTB <- data$class2useTB
  TBscores <- data$TBscores
  TBclass <- data$TBclass
  TBclass_above_threshold <- data$TBclass.above.threshold

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
#' \dontrun{
#' volume <- c(5000, 10000, 20000)
#' vol2C_lgdiatom(volume)
#' }
vol2C_lgdiatom <- function(volume) {
  loga <- -0.933
  b <- 0.881
  logC <- loga + b * log10(volume)
  carbon <- 10^logC
  return(carbon)
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
#' \dontrun{
#' volume <- c(5000, 10000, 20000)
#' vol2C_nondiatom(volume)
#' }
vol2C_nondiatom <- function(volume) {
  loga <- -0.665
  b <- 0.939
  logC <- loga + b * log10(volume)
  carbon <- 10^logC
  return(carbon)
}

#' Handle Missing Positions by Rounding Timestamps
#'
#' This function handles missing GPS positions by rounding the timestamps
#' to the nearest minute using a specified rounding function, and then
#' merging the resulting timestamps with the ferrybox position data.
#' It updates the missing latitude and longitude values based on the
#' rounded timestamps.
#'
#' @param data A data frame containing timestamps and GPS positions.
#' @param rounding_function A function used to round the timestamps.
#' This can be `lubridate::floor_date`, `lubridate::ceiling_date`,
#' or any other suitable rounding function.
#' @param lat_col The name of the new latitude column to be created.
#' @param lon_col The name of the new longitude column to be created.
#'
#' @return A data frame with updated GPS positions where the positions were missing.
#' The returned data frame contains the original timestamps and the new columns
#' for latitude and longitude based on the rounded timestamps.
#'
#' @examples
#' # Example usage:
#' data <- data.frame(timestamp = Sys.time() + 1:10 * 60,
#'                    gpsLatitude = c(NA, runif(9)),
#'                    gpsLongitude = c(NA, runif(9)))
#' ferrybox_position <- data.frame(timestamp_minute = lubridate::round_date(Sys.time(),
#'                                                                          "minutes") + 1:10 * 60,
#'                                 ferrybox_latitude = runif(10),
#'                                 ferrybox_longitude = runif(10))
#' if(lubridate::second(Sys.time()) < 30) {
#'   updated_data <- iRfcb:::handle_missing_positions(data,
#'                                                    ferrybox_position,
#'                                                    lubridate::floor_date,
#'                                                    "gpsLatitude_floor",
#'                                                    "gpsLongitude_floor")
#' } else {
#'   updated_data <- iRfcb:::handle_missing_positions(data,
#'                                                    ferrybox_position,
#'                                                    lubridate::ceiling_date,
#'                                                    "gpsLatitude_floor",
#'                                                    "gpsLongitude_floor")
#' }
#' @importFrom magrittr %>%
#' @importFrom dplyr filter mutate left_join select coalesce
handle_missing_positions <- function(data, ferrybox_position, rounding_function, lat_col, lon_col) {
  data %>%
    filter(is.na(gpsLatitude)) %>%
    mutate(timestamp_minute = rounding_function(timestamp, unit = "minute")) %>%
    left_join(ferrybox_position, by = "timestamp_minute") %>%
    mutate(
      !!lat_col := coalesce(gpsLatitude, ferrybox_latitude),
      !!lon_col := coalesce(gpsLongitude, ferrybox_longitude)
    ) %>%
    select(timestamp, !!lat_col, !!lon_col)
}
