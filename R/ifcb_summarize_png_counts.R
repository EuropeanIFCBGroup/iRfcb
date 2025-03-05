#' Summarize Image Counts by Class and Sample
#'
#' This function summarizes the number of images per class for each sample and timestamps,
#' and optionally retrieves GPS positions, and IFCB information using `ifcb_read_hdr_data` and `ifcb_convert_filenames` functions.
#'
#' @param png_folder A character string specifying the path to the main directory containing subfolders (classes) with .png images.
#' @param hdr_folder A character string specifying the path to the directory containing the .hdr files. Default is NULL.
#' @param sum_level A character string specifying the level of summarization. Options: "sample" (default) or "class".
#' @param verbose A logical indicating whether to print progress messages. Default is TRUE.
#' @return If sum_level is "sample", returns a data frame with columns: sample, ifcb_number, class_name, n_images, gpsLatitude, gpsLongitude, timestamp, year, month, day, time, roi_numbers.
#'         If sum_level is "class", returns a data frame with columns: class_name, n_images.
#'
#' @export
#' @seealso \code{\link{ifcb_read_hdr_data}} \code{\link{ifcb_convert_filenames}}
#'
#' @examples
#' \dontrun{
#' # Example usage:
#' # Assuming the following directory structure:
#' # path/to/png_folder/
#' # |- class1/
#' # |  |- sample1_00001.png
#' # |  |- sample1_00002.png
#' # |  |- sample2_00001.png
#' # |- class2/
#' # |  |- sample1_00003.png
#' # |  |- sample3_00001.png
#'
#' png_folder <- "path/to/png_folder"
#' hdr_folder <- "path/to/hdr_folder" # This folder should contain corresponding .hdr files
#'
#' # Summarize by sample
#' summary_sample <- ifcb_summarize_png_counts(png_folder,
#'                                           hdr_folder,
#'                                           sum_level = "sample",
#'                                           verbose = TRUE)
#' print(summary_sample)
#'
#' # Summarize by class
#' summary_class <- ifcb_summarize_png_counts(png_folder,
#'                                          hdr_folder,
#'                                          sum_level = "class",
#'                                          verbose = TRUE)
#' print(summary_class)
#' }
ifcb_summarize_png_counts <- function(png_folder, hdr_folder = NULL, sum_level = "sample", verbose = TRUE) {
  # List all subdirectories (classes) directly under the main directory
  subdirs <- list.dirs(png_folder, recursive = FALSE, full.names = FALSE)

  # Stop function if there are no subdirectories in the png folder
  if (length(subdirs) == 0) {
    stop("No subdirectories found in the PNG folder")
  }

  # Initialize an empty list to store results
  results <- list()

  # Check if sum_level is "class", then skip HDR extraction
  if (sum_level == "sample" && !is.null(hdr_folder) && dir.exists(hdr_folder)) {
    hdr_info <- ifcb_read_hdr_data(file.path(hdr_folder), verbose = FALSE)
  } else {
    hdr_info <- NULL
  }

  # Iterate through each subdirectory (class)
  for (subdir in subdirs) {
    class_name <- subdir  # Assuming subdir name is the class name

    # List all PNG files in the current subdirectory
    png_files <- list.files(file.path(png_folder, subdir), pattern = "\\.png$", full.names = TRUE)

    # Initialize a list to store results for the current class
    class_results <- list()

    # Iterate through each PNG file
    for (png_file in png_files) {
      # Extract sample name and IFCB number from PNG filename
      filename <- tools::file_path_sans_ext(basename(png_file))
      parts <- strsplit(filename, "_", fixed = TRUE)[[1]]
      sample_name <- paste(parts[1], parts[2], sep = "_")
      ifcb_number <- parts[2]  # Extract IFCB number directly
      roi_number <- as.integer(parts[3])

      if (is.null(hdr_info)) {
        # If hdr_info is not available or sum_level is "class", use ifcb_convert_filenames directly
        gps_timestamp <- ifcb_convert_filenames(sample_name)
        gpsLatitude <- NA
        gpsLongitude <- NA
        timestamp <- gps_timestamp$timestamp
        date <- gps_timestamp$date
        year <- gps_timestamp$year
        month <- gps_timestamp$month
        day <- gps_timestamp$day
        time <- gps_timestamp$time
      } else {
        # Find the matching entry in hdr_info if sum_level is "sample"
        match_row <- hdr_info$sample == sample_name
        if (sum_level == "sample" && any(match_row)) {
          gpsLatitude <- hdr_info$gpsLatitude[match_row]
          gpsLongitude <- hdr_info$gpsLongitude[match_row]
          timestamp <- hdr_info$timestamp[match_row]
          date <- lubridate::date(timestamp)
          year <- lubridate::year(timestamp)
          month <- lubridate::month(timestamp)
          day <- lubridate::day(timestamp)
          time <- format(timestamp, "%H:%M:%S")
        } else {
          # If sum_level is "class" or no match found (unlikely case), set to NA
          gps_timestamp <- ifcb_convert_filenames(sample_name)
          gpsLatitude <- NA
          gpsLongitude <- NA
          timestamp <- gps_timestamp$timestamp
          date <- gps_timestamp$date
          year <- gps_timestamp$year
          month <- gps_timestamp$month
          day <- gps_timestamp$day
          time <- gps_timestamp$time
        }
      }

      # Append results for the current PNG file to class_results
      class_results[[length(class_results) + 1]] <- data.frame(
        sample = sample_name,
        ifcb_number = ifcb_number,
        class_name = class_name,
        n_images = 1,  # Each row represents one image
        gpsLatitude = gpsLatitude,
        gpsLongitude = gpsLongitude,
        timestamp = timestamp,
        date = date,
        year = year,
        month = month,
        day = day,
        time = time,
        roi_numbers = as.character(roi_number)  # Store roi_number as character
      )
    }

    # Combine results for the current class and store in results
    class_results_df <- do.call(rbind, class_results)
    if (sum_level == "sample") {
      class_summary <- class_results_df %>%
        group_by(sample, ifcb_number, class_name) %>%
        summarise(
          n_images = n(),
          roi_numbers = paste(roi_numbers, collapse = ", "),  # Combine roi_numbers into a single string
          gpsLatitude = first(gpsLatitude),   # Take the first value of gpsLatitude (assuming it's constant per sample)
          gpsLongitude = first(gpsLongitude), # Take the first value of gpsLongitude (assuming it's constant per sample)
          timestamp = first(timestamp),       # Take the first value of timestamp (assuming it's constant per sample)
          date = first(date),                 # Take the first value of date (assuming it's constant per sample)
          year = first(year),                 # Take the first value of year (assuming it's constant per sample)
          month = first(month),               # Take the first value of month (assuming it's constant per sample)
          day = first(day),                   # Take the first value of day (assuming it's constant per sample)
          time = first(time),                 # Take the first value of time (assuming it's constant per sample)
          .groups = "drop_last"
        )
    } else if (sum_level == "class") {
      class_summary <- class_results_df %>%
        group_by(class_name) %>%
        summarise(
          n_images = n(),
          .groups = "drop_last"
        )
    }

    # Store summarized results
    results[[class_name]] <- class_summary
  }

  # Combine all results into a single data frame
  final_results <- do.call(bind_rows, results)

  # Remove the trailing _NNN from each class name, if present
  final_results$class_name <- gsub("_\\d{3}$", "", final_results$class_name)

  # Remove row names
  rownames(final_results) <- NULL

  return(arrange(final_results, if (sum_level == "sample") sample else class_name))
}
