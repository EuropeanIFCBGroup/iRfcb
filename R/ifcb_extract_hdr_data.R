utils::globalVariables(c("parameter", "roi_numbers"))
#' Extract HDR data from IFCB HDR Files
#'
#' This function reads all IFCB instrument settings information files (.hdr) from a specified directory,
#' and extracts the GPS positions if available (optionally).
#'
#' @param hdrdir A character string specifying the path to the directory containing the .hdr files.
#' @param gps_only A logical indicating whether to include only GPS information (latitude and longitude). Default is FALSE.
#' @param verbose A logical indicating whether to print progress messages. Default is TRUE.
#' @return A data frame with sample names, GPS latitude, GPS longitude, and optionally timestamps.
#' @examples
#' \dontrun{
#' # Extract all HDR data
#' hdr_data <- ifcb_extract_hdr_data("path/to/data")
#' print(hdr_data)
#'
#' # Extract only GPS data
#' gps_data <- ifcb_extract_hdr_data("path/to/data", gps_only = TRUE)
#' print(gps_data)
#' }
#' @importFrom dplyr mutate select
#' @importFrom tidyr pivot_wider
#' @export
ifcb_extract_hdr_data <- function(hdrdir, gps_only = FALSE, verbose = TRUE) {
  # List all .hdr files in the specified directory
  files <- list.files(hdrdir, pattern = "\\.hdr$", recursive = TRUE, full.names = TRUE)

  # Read all files into a list of data frames
  all_hdr_data_list <- lapply(files, read_hdr_file) # Helper function

  # Combine all data frames into one, filtering out those without GPS data if gps_only is TRUE
  if (gps_only) {
    hdr_data <- do.call(rbind, all_hdr_data_list)
    hdr_data <- hdr_data[hdr_data$parameter %in% c("gpsLatitude", "gpsLongitude"), ]
  } else {
    hdr_data <- do.call(rbind, all_hdr_data_list)
  }

  # Check if there is any data to process
  if (nrow(hdr_data) == 0) {
    stop("No files with gpsLatitude and gpsLongitude found.")
  }

  # Transform data to wide format
  hdr_data_pivot <- tidyr::pivot_wider(data = hdr_data,
                                       names_from = parameter,
                                       values_from = value)

  # Extract sample names from filenames
  hdr_data_pivot$sample <- tools::file_path_sans_ext(basename(hdr_data_pivot$file))

  if (!gps_only) {
    # Extract timestamps using ifcb_convert_filenames function
    filenames <- paste0(hdr_data_pivot$sample, ".hdr")
    timestamps <- ifcb_convert_filenames(filenames)

    # Merge positions with timestamps
    hdr_with_timestamps <- merge(hdr_data_pivot, timestamps, by = "sample", all.x = TRUE)

    return(dplyr::select(hdr_with_timestamps, -file))
  } else {
    # Convert filenames to get timestamps even when gps_only is TRUE
    filenames <- paste0(hdr_data_pivot$sample, ".hdr")
    timestamps <- ifcb_convert_filenames(filenames)
    hdr_data_pivot <- merge(hdr_data_pivot, timestamps, by = "sample", all.x = TRUE)

    # Remove the 'file' column if only GPS data is returned
    return(dplyr::select(hdr_data_pivot, -file))
  }
}
