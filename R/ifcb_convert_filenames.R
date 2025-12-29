#' Convert IFCB Filenames to Timestamps
#'
#' This function converts IFCB filenames to a data frame with separate columns for
#' the sample name, full timestamp, year, month, day, time, and IFCB number.
#' ROI numbers are included if available.
#'
#' @param filenames A character vector of IFCB filenames in the format "DYYYYMMDDTHHMMSS_IFCBxxx"
#'   or "IFCBxxx_YYYY_DDD_HHMMSS". Filenames can optionally include an ROI number,
#'   which will be extracted if present.
#' @param tz Character. Time zone to assign to the extracted timestamps.
#'   Defaults to "UTC". Set this to a different time zone if needed.
#'
#' @return A tibble with the following columns:
#'   - `sample`: The extracted sample name (character).
#'   - `full_timestamp`: The full timestamp in "YYYY-MM-DD HH:MM:SS" format (POSIXct).
#'   - `year`: The year extracted from the timestamp (integer).
#'   - `month`: The month extracted from the timestamp (integer).
#'   - `day`: The day extracted from the timestamp (integer).
#'   - `time`: The extracted time in "HH:MM:SS" format (character).
#'   - `ifcb_number`: The IFCB instrument number (character).
#'   - `roi`: The extracted ROI number if available (integer or `NA`).
#'
#'   If the `roi` column is empty (all `NA`), it will be excluded from the output.
#'
#' @examples
#' filenames <- c("D20230314T001205_IFCB134", "D20230615T123045_IFCB135")
#' timestamps <- ifcb_convert_filenames(filenames)
#' print(timestamps)
#'
#' @export
ifcb_convert_filenames <- function(filenames, tz = "UTC") {

  # If input is empty, return an empty data frame with the correct structure
  if (length(filenames) == 0) {
    return(tibble(
      sample = character(0),
      timestamp = as.POSIXct(character(0), tz = tz),
      date = as.Date(character(0)),
      year = integer(0),
      month = integer(0),
      day = integer(0),
      time = character(0),
      ifcb_number = character(0)
    ))
  }

  # Remove extension if present
  filenames <- tools::file_path_sans_ext(filenames)

  # Check if filenames are in the correct format
  valid_format <- grepl("^[A-Z]\\d{8}T\\d{6}|^IFCB\\d+_\\d{4}_\\d{3}_\\d{6}", filenames)
  if (!all(valid_format)) {
    stop("Error: One or more filenames are not in the correct format.")
  }

  # Apply the extraction function to all filenames and combine results
  timestamps <- extract_parts(filenames, tz = tz)

  if (nrow(timestamps) > 0) {
    timestamps <- suppressMessages(type_convert(timestamps))
  }

  # Remove `roi` column entirely if it doesn't exist or if all values are NA
  if ("roi" %in% colnames(timestamps) && all(is.na(timestamps$roi))) {
    timestamps <- timestamps %>% dplyr::select(-roi)
  }

  timestamps
}
