#' Convert IFCB Filenames to Timestamps
#'
#' This function converts IFCB filenames to a data frame with separate columns for
#' the sample name, full timestamp, year, month, day, time, and IFCB number.
#' ROI numbers are included if available.
#'
#' @param filenames A character vector of IFCB filenames in the format "DYYYYMMDDTHHMMSS_IFCBxxx".
#'
#' @return A tibble with columns:
#'   - `sample`: The extracted sample name.
#'   - `full_timestamp`: The full timestamp in "YYYY-MM-DD HH:MM:SS" format.
#'   - `year`: The year as an integer.
#'   - `month`: The month as an integer.
#'   - `day`: The day as an integer.
#'   - `time`: The extracted time in "HH:MM:SS" format.
#'   - `ifcb_number`: The IFCB instrument number.
#'
#' @examples
#' filenames <- c("D20230314T001205_IFCB134", "D20230615T123045_IFCB135")
#' timestamps <- ifcb_convert_filenames(filenames)
#' print(timestamps)
#'
#' @export
ifcb_convert_filenames <- function(filenames) {

  # Remove extension if present
  filenames <- tools::file_path_sans_ext(filenames)

  # Check if filenames are in the correct format
  valid_format <- grepl("^D\\d{8}T\\d{6}", filenames)
  if (!all(valid_format)) {
    stop("Error: One or more filenames are not in the correct format.")
  }

  # Apply the extraction function to all filenames and combine results
  timestamps_list <- lapply(filenames, extract_parts) # Helper function
  timestamps <- do.call(bind_rows, timestamps_list)

  if (nrow(timestamps) > 0) {
    timestamps <- suppressMessages(type_convert(timestamps))
  }

  timestamps
}
