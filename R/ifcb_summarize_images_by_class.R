#' Summarize Image Counts by Class and Sample
#'
#' This function summarizes the number of images per class for each sample,
#' and optionally retrieves GPS positions, timestamps, and IFCB information using ifcb_extract_hdr_data and ifcb_convert_filenames functions.
#'
#' @param png_directory A character string specifying the path to the main directory containing subfolders (classes) with .png images.
#' @param hdr_directory A character string specifying the path to the directory containing the .hdr files. Default is NULL.
#' @param verbose A logical indicating whether to print progress messages. Default is TRUE.
#' @return A data frame with columns: sample, ifcb_number, class_name, n_images, gpsLatitude, gpsLongitude, timestamp, year, month, day, time, roi_numbers.
#' @importFrom dplyr group_by summarise bind_rows arrange
#' @importFrom lubridate date year month day
#' @export
ifcb_summarize_images_by_class <- function(png_directory, hdr_directory = NULL, verbose = TRUE) {
  # List all subdirectories (classes) directly under the main directory
  subdirs <- list.dirs(png_directory, recursive = FALSE, full.names = FALSE)

  # Initialize an empty list to store results
  results <- list()

  # Check if hdr_directory is provided and exists
  if (!is.null(hdr_directory) && dir.exists(hdr_directory)) {
    hdr_info <- ifcb_extract_hdr_data(file.path(hdr_directory), verbose = FALSE)
  } else {
    hdr_info <- NULL
  }

  # Iterate through each subdirectory (class)
  for (subdir in subdirs) {
    class_name <- subdir  # Assuming subdir name is the class name

    # List all PNG files in the current subdirectory
    png_files <- list.files(file.path(png_directory, subdir), pattern = "\\.png$", full.names = TRUE)

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
        # If hdr_info is not available, use ifcb_convert_filenames directly
        gps_timestamp <- ifcb_convert_filenames(sample_name)
        gpsLatitude <- NA
        gpsLongitude <- NA
        timestamp <- gps_timestamp$full_timestamp
        date <- gps_timestamp$date
        year <- gps_timestamp$year
        month <- gps_timestamp$month
        day <- gps_timestamp$day
        time <- gps_timestamp$time
      } else {
        # Find the matching entry in hdr_info
        match_row <- hdr_info$sample == sample_name
        if (any(match_row)) {
          gpsLatitude <- hdr_info$gpsLatitude[match_row]
          gpsLongitude <- hdr_info$gpsLongitude[match_row]
          timestamp <- hdr_info$full_timestamp[match_row]
          date <- lubridate::date(timestamp)
          year <- lubridate::year(timestamp)
          month <- lubridate::month(timestamp)
          day <- lubridate::day(timestamp)
          time <- format(timestamp, "%H:%M:%S")
        } else {
          # If no match found (unlikely case), set to NA
          gps_timestamp <- ifcb_convert_filenames(sample_name)
          gpsLatitude <- NA
          gpsLongitude <- NA
          timestamp <- gps_timestamp$full_timestamp
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

    # Store summarized results
    results[[class_name]] <- class_summary
  }

  # Combine all results into a single data frame
  final_results <- do.call(bind_rows, results)

  # Remove row names
  rownames(final_results) <- NULL

  return(arrange(final_results, sample))
}
