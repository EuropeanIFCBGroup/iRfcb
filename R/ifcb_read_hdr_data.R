utils::globalVariables(c("parameter", "roi_numbers"))

#' Reads HDR Data from IFCB HDR Files
#'
#' This function reads all IFCB instrument settings information files (.hdr) from a specified directory.
#'
#' @param hdr_files A character string specifying the path to feature files or a folder path.
#' @param gps_only A logical value indicating whether to include only GPS information (latitude and longitude). Default is FALSE.
#' @param verbose A logical value indicating whether to print progress messages. Default is TRUE.
#' @param hdr_folder `r lifecycle::badge("deprecated")`
#'
#'    Use \code{hdr_files} instead.
#'
#' @return A data frame with sample names, GPS latitude, GPS longitude, and optionally timestamps.
#' @examples
#' \dontrun{
#' # Extract all HDR data
#' hdr_data <- ifcb_read_hdr_data("path/to/data")
#' print(hdr_data)
#'
#' # Extract only GPS data
#' gps_data <- ifcb_read_hdr_data("path/to/data", gps_only = TRUE)
#' print(gps_data)
#' }
#'
#' @importFrom dplyr mutate select
#' @importFrom tidyr pivot_wider
#' @importFrom readr type_convert cols col_character
#' @importFrom lifecycle is_present deprecate_warn deprecated
#'
#' @export
ifcb_read_hdr_data <- function(hdr_files, gps_only = FALSE, verbose = TRUE, hdr_folder = deprecated()) {

  # Warn the user if feature_folder is used
  if (lifecycle::is_present(hdr_folder)) {

    # Signal the deprecation to the user
    deprecate_warn("0.3.11", "iRfcb::ifcb_read_hdr_data(hdr_folder = )", "iRfcb::ifcb_read_hdr_data(hdr_files = )")

    # Deal with the deprecated argument for compatibility
    hdr_files <- hdr_folder
  }

  # Check if feature_files is a single folder path or a vector of file paths
  if (length(hdr_files) == 1 && file.info(hdr_files)$isdir) {
    hdr_files <- list.files(hdr_files, pattern = "\\.hdr$", recursive = TRUE, full.names = TRUE)
  }

  if (verbose) cat("Found", length(hdr_files), ".hdr files.\n")

  # Read all files into a list of data frames using a helper function
  all_hdr_data_list <- lapply(hdr_files, read_hdr_file) # Helper function to read individual HDR files

  # Combine all data frames into one
  hdr_data <- do.call(rbind, all_hdr_data_list)

  # Check if there is any data to process
  if (is.null(hdr_data)) {
    stop("No HDR data found. Check the folder path or ensure the files contain the required data.")
  }

  # Transform data to wide format
  hdr_data_pivot <- tidyr::pivot_wider(data = hdr_data, names_from = parameter, values_from = value)

  # Extract sample names from filenames
  hdr_data_pivot$sample <- tools::file_path_sans_ext(basename(hdr_data_pivot$file))

  # Filter out non-GPS data if gps_only is TRUE
  if (gps_only) {
    hdr_data_pivot <- dplyr::select(hdr_data_pivot, file, sample, gpsLatitude, gpsLongitude)
  }

  # Extract timestamps using ifcb_convert_filenames function
  filenames <- paste0(hdr_data_pivot$sample, ".hdr")
  timestamps <- ifcb_convert_filenames(filenames)

  # Merge positions with timestamps
  hdr_data_pivot <- merge(hdr_data_pivot, timestamps, by = "sample", all.x = TRUE)

  # Convert column types
  hdr_data_pivot <- suppressMessages(type_convert(hdr_data_pivot,
                                                  col_types = cols(GPSFeed = col_character())))

  if (verbose) cat("Processing completed.\n")

  # Remove the 'file' column from the final data frame
  return(dplyr::select(hdr_data_pivot, -file))
}
