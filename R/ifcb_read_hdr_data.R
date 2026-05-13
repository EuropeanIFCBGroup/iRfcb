utils::globalVariables(c("parameter", "roi_numbers"))

#' Read Data from IFCB HDR Files
#'
#' This function reads all IFCB instrument settings information files (.hdr) from a specified directory.
#'
#' @param hdr_files A character string or character vector specifying the path(s) to `.hdr` files, or a single folder path.
#' @param gps_only A logical value indicating whether to include only GPS information (latitude and longitude). Default is FALSE.
#' @param verbose A logical value indicating whether to print progress messages. Default is TRUE.
#' @param hdr_folder `r lifecycle::badge("deprecated")`
#'
#'    Use \code{hdr_files} instead.
#'
#' @return A data frame with sample names, GPS latitude, GPS longitude, and timestamps. When `gps_only = TRUE`, only samples with GPS coordinates are included.
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
#' @export
ifcb_read_hdr_data <- function(hdr_files, gps_only = FALSE, verbose = TRUE, hdr_folder = deprecated()) {

  # Warn the user if hdr_folder is used
  if (lifecycle::is_present(hdr_folder)) {

    # Signal the deprecation to the user
    deprecate_warn("0.3.11", "iRfcb::ifcb_read_hdr_data(hdr_folder = )", "iRfcb::ifcb_read_hdr_data(hdr_files = )")

    # Deal with the deprecated argument for compatibility
    hdr_files <- hdr_folder
  }

  # Check if hdr_files is a single folder path or a vector of file paths
  if (length(hdr_files) == 1 && dir.exists(hdr_files)) {
    hdr_files <- list.files(
      hdr_files,
      pattern = "\\.hdr$",
      recursive = TRUE,
      full.names = TRUE
    )
  }

  if (!all(file.exists(hdr_files))) {
    missing <- hdr_files[!file.exists(hdr_files)]
    cli_abort(c(
      "{length(missing)} {.arg hdr_files} do{?es/} not exist:",
      "x" = "{.file {missing}}"
    ))
  }

  if (verbose) cli_inform("Found {length(hdr_files)} {.file .hdr} file{?s}.")
  if (verbose) cli_progress_bar("Reading HDR files", total = length(hdr_files))

  # Read all files into a list of data frames using a helper function
  all_hdr_data_list <- lapply(seq_along(hdr_files), function(i) {
    # Update the progress bar
    if (verbose) cli_progress_update()

    # Call the helper function
    read_hdr_file(hdr_files[[i]])
  })

  if (verbose) cli_progress_done()

  # Combine all data frames into one
  hdr_data <- bind_rows(all_hdr_data_list)

  # Check if there is any data to process
  if (nrow(hdr_data) == 0) {
    cli_abort(c(
      "No HDR data found.",
      "i" = "Check the folder path or ensure the files contain the required data."
    ))
  }

  # Fix unique names, e.g. runType from IFCBAquire 1.x.x.x
  hdr_data <- hdr_data %>%
    dplyr::group_by(file, parameter) %>%
    dplyr::mutate(
      parameter = if (n() > 1) paste0(parameter, "_", dplyr::row_number()) else parameter
    ) %>%
    dplyr::ungroup()

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
  hdr_data_pivot <- left_join(hdr_data_pivot, timestamps, by = "sample")

  # Convert column types
  hdr_data_pivot <- suppressMessages(type_convert(hdr_data_pivot,
                                                  col_types = cols(GPSFeed = col_character())))

  if (verbose) cli_alert_success("Processing completed.")

  # Remove the 'file' column from the returned data frame
  dplyr::select(hdr_data_pivot, -file)
}
