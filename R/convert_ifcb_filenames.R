#' Convert IFCB Filenames to Timestamps
#'
#' This function converts IFCB filenames to a data frame with separate columns for
#' the sample name, full timestamp, year, month, day, time, and IFCB number.
#'
#' @param filenames A character vector of IFCB filenames in the format "DYYYYMMDDTHHMMSS_IFCBxxx".
#' @return A data frame with columns: sample, full_timestamp, year, month, day, time, and ifcb_number.
#' @examples
#' \dontrun{
#' filenames <- c("D20230314T001205_IFCB134", "D20230615T123045_IFCB135")
#' timestamps <- convert_ifcb_filenames(filenames)
#' print(timestamps)
#' }
#' @importFrom stringr str_extract str_remove_all
#' @importFrom lubridate ymd_hms
#' @export
convert_ifcb_filenames <- function(filenames) {
  # Extract parts using regular expressions
  extract_parts <- function(filename) {
    timestamp_str <- stringr::str_extract(filename, "D\\d{8}T\\d{6}")
    ifcb_number <- stringr::str_extract(filename, "IFCB\\d+")

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

    return(data.frame(
      sample = tools::file_path_sans_ext(filename),  # Extract sample name without extension
      timestamp = full_timestamp,
      date = date,
      year = year,
      month = month,
      day = day,
      time = time,
      ifcb_number = ifcb_number,
      stringsAsFactors = FALSE
    ))
  }

  # Apply the extraction function to all filenames and combine results
  timestamps_list <- lapply(filenames, extract_parts)
  timestamps <- do.call(rbind, timestamps_list)

  return(timestamps)
}

# Example usage
# filenames <- c("D20230314T001205_IFCB134", "D20230615T123045_IFCB135")
# timestamps <- convert_ifcb_filenames(filenames)
# print(timestamps)
