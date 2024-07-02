utils::globalVariables(c("date_from", "date_to", "in_range", "timestamp_minute", "ferrybox_latitude", "ferrybox_longitude", '38059', '8002', '8003'))

#' Get GPS coordinates from ferrybox data based on timestamps
#'
#' This function reads .txt files from a specified folder containing ferrybox data,
#' filters them based on a specified ship name (default is "SveaFB" for R/V Svea), and extracts
#' GPS coordinates for timestamps (nearest minute) falling within the date ranges defined in the file names.
#'
#' @param timestamps A vector of POSIXct timestamps for which GPS coordinates are to be retrieved.
#' @param ferrybox_folder Path to the folder containing ferrybox .txt files.
#' @param ship Name of the ship to filter ferrybox files (default is "SveaFB").
#'
#' @return A data frame containing the input timestamps and corresponding GPS coordinates.
#'   Columns include 'timestamp', 'gpsLatitude', and 'gpsLongitude'.
#'
#' @examples
#' \dontrun{
#' ferrybox_folder <- "/path/to/ferrybox/data"
#' timestamps <- as.POSIXct(c("2016-08-10 10:47:34 UTC",
#'                            "2016-08-10 11:12:21 UTC",
#'                            "2016-08-10 11:35:59 UTC"))
#'
#' result <- ifcb_get_svea_position(timestamps, ferrybox_folder)
#' print(result)
#' }
#'
#' @importFrom dplyr filter rowwise mutate ungroup left_join rename select %>%
#' @importFrom lubridate round_date ymd_hms
#'
#' @export
ifcb_get_svea_position <- function(timestamps, ferrybox_folder, ship = "SveaFB") {
  # List all .txt files in the specified folder (excluding subfolders)
  ferrybox_files <- list.files(ferrybox_folder, pattern = "\\.txt$", full.names = TRUE, recursive = FALSE)

  # Convert ferrybox file names to dataframe and extract timestamps
  ferrybox_files_df <- data.frame(ferrybox_files = ferrybox_files) %>%
    dplyr::filter(grepl(ship, ferrybox_files)) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      date_from = as.POSIXct(substr(regmatches(ferrybox_files, gregexpr("\\d{14}", ferrybox_files))[[1]][1], 1, 14),
                                        format = "%Y%m%d%H%M%S", tz = "UTC"),
      date_to = as.POSIXct(substr(regmatches(ferrybox_files, gregexpr("\\d{14}", ferrybox_files))[[1]][2], 1, 14),
                                      format = "%Y%m%d%H%M%S", tz = "UTC")
    ) %>%
    dplyr::ungroup()

  # Create a logical column indicating if any timestamp falls within the date range
  ferrybox_files_df <- ferrybox_files_df %>%
    dplyr::rowwise() %>%
    dplyr::mutate(in_range = any(timestamps >= date_from & timestamps <= date_to)) %>%
    dplyr::ungroup()

  # Filter the dataframe based on the in_range column
  filtered_ferrybox_files_df <- ferrybox_files_df %>%
    dplyr::filter(in_range)

  # Initialize an empty data frame to store ferrybox data
  ferrybox_data <- data.frame()

  # Read and concatenate data from filtered ferrybox files
  for (file in filtered_ferrybox_files_df$ferrybox_files) {
    ferrybox_data_temp <- read.table(file,
                                     header = TRUE,
                                     sep = "\t",
                                     stringsAsFactors = FALSE,
                                     check.names = FALSE,
                                     colClasses = "character",
                                     na.strings = "")
    ferrybox_data <- dplyr::bind_rows(ferrybox_data, ferrybox_data_temp)
  }

  # Extract and clean ferrybox position data
  ferrybox_position <- ferrybox_data %>%
    mutate(timestamp_minute = ymd_hms(as.numeric(`38059`), tz = "UTC"),
           ferrybox_latitude = as.numeric(`8002`),
           ferrybox_longitude = as.numeric(`8003`)) %>%
    select(timestamp_minute, ferrybox_latitude, ferrybox_longitude)

  # Merge the ferrybox position data with the input timestamps
  output <- data.frame(timestamp = timestamps) %>%
    dplyr::mutate(timestamp_minute = lubridate::round_date(timestamp, unit = "minute")) %>%
    dplyr::left_join(ferrybox_position, by = "timestamp_minute") %>%
    dplyr::rename(gpsLatitude = ferrybox_latitude, gpsLongitude = ferrybox_longitude) %>%
    dplyr::select(timestamp, gpsLatitude, gpsLongitude)

  return(output)
}
