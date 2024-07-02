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
#' @importFrom dplyr filter rowwise mutate ungroup left_join rename select
#' @importFrom magrittr %>%
#' @importFrom lubridate round_date ymd_hms
#'
#' @export
ifcb_get_svea_position <- function(timestamps, ferrybox_folder, ship = "SveaFB") {
  # Validate inputs
  if (!inherits(timestamps, "POSIXct")) {
    stop("The 'timestamps' argument must be a vector of POSIXct timestamps.")
  }

  if (!dir.exists(ferrybox_folder)) {
    stop("The specified ferrybox folder does not exist.")
  }

  # List all .txt files in the specified folder (excluding subfolders)
  ferrybox_files <- list.files(ferrybox_folder, pattern = "\\.txt$", full.names = TRUE, recursive = FALSE)

  if (length(ferrybox_files) == 0) {
    stop("No .txt files found in the specified ferrybox folder.")
  }

  # Convert ferrybox file names to dataframe and extract timestamps
  ferrybox_files_df <- data.frame(ferrybox_files = ferrybox_files) %>%
    dplyr::filter(grepl(ship, ferrybox_files)) %>%
    dplyr::rowwise()

  if (nrow(ferrybox_files_df) == 0) {
    stop("No ferrybox files matching the specified ship name were found.")
  }

  ferrybox_files_df <- ferrybox_files_df %>%
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

  if (nrow(filtered_ferrybox_files_df) == 0) {
    stop("No ferrybox files contain data within the provided timestamps.")
  }

  # Initialize an empty data frame to store ferrybox data
  ferrybox_data <- data.frame()

  # Read and concatenate data from filtered ferrybox files
  for (file in filtered_ferrybox_files_df$ferrybox_files) {
    ferrybox_data_temp <- tryCatch({
      read.table(file,
                 header = TRUE,
                 sep = "\t",
                 stringsAsFactors = FALSE,
                 check.names = FALSE,
                 colClasses = "character",
                 na.strings = "")
    }, error = function(e) {
      warning(paste("Failed to read file:", file, "-", e$message))
      return(NULL)
    })

    if (!is.null(ferrybox_data_temp)) {
      ferrybox_data <- dplyr::bind_rows(ferrybox_data, ferrybox_data_temp)
    }
  }

  if (nrow(ferrybox_data) == 0) {
    stop("No valid ferrybox data could be read from the filtered files.")
  }

  # Extract and clean ferrybox position data
  ferrybox_position <- ferrybox_data %>%
    dplyr::mutate(
      timestamp_minute = tryCatch({
        ymd_hms(as.numeric(`38059`), tz = "UTC")
      }, error = function(e) {
        stop("Error parsing ferrybox timestamp data.")
      }),
      ferrybox_latitude = tryCatch({
        as.numeric(`8002`)
      }, error = function(e) {
        stop("Error parsing latitude data.")
      }),
      ferrybox_longitude = tryCatch({
        as.numeric(`8003`)
      }, error = function(e) {
        stop("Error parsing longitude data.")
      })
    ) %>%
    dplyr::select(timestamp_minute, ferrybox_latitude, ferrybox_longitude)

  if (nrow(ferrybox_position) == 0) {
    stop("No valid position data could be extracted from the ferrybox data.")
  }

  # Merge the ferrybox position data with the input timestamps
  output <- data.frame(timestamp = timestamps) %>%
    dplyr::mutate(timestamp_minute = lubridate::round_date(timestamp, unit = "minute")) %>%
    dplyr::left_join(ferrybox_position, by = "timestamp_minute") %>%
    dplyr::rename(gpsLatitude = ferrybox_latitude, gpsLongitude = ferrybox_longitude) %>%
    dplyr::select(timestamp, gpsLatitude, gpsLongitude)

  return(output)
}
