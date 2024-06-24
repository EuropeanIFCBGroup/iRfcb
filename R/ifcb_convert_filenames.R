#' Convert IFCB Filenames to Timestamps
#'
#' This function converts IFCB filenames to a data frame with separate columns for
#' the sample name, full timestamp, year, month, day, time, and IFCB number.
#' ROI numbers are included if available.
#'
#' @param filenames A character vector of IFCB filenames in the format "DYYYYMMDDTHHMMSS_IFCBxxx".
#' @return A data frame with columns: sample, full_timestamp, year, month, day, time, and ifcb_number.
#' @examples
#' \dontrun{
#' filenames <- c("D20230314T001205_IFCB134", "D20230615T123045_IFCB135")
#' timestamps <- ifcb_convert_filenames(filenames)
#' print(timestamps)
#' }
#' @importFrom stringr str_extract str_remove_all
#' @importFrom lubridate ymd_hms
#' @importFrom dplyr bind_rows
#' @export
ifcb_convert_filenames <- function(filenames) {
  # Apply the extraction function to all filenames and combine results
  timestamps_list <- lapply(filenames, extract_parts) # Helper function
  timestamps <- do.call(bind_rows, timestamps_list)

  return(timestamps)
}
