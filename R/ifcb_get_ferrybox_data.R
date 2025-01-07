utils::globalVariables(c("date_from", "date_to", "in_range", "timestamp_minute", '38059', 'timestamp_minute_temp', 'time_difference', 'n'))

#' Retrieve Ferrybox Data for Specified Timestamps
#'
#' This internal SMHI function reads `.txt` files from a specified folder containing Ferrybox data,
#' filters them based on a specified ship name (default is "SveaFB" for R/V Svea), and extracts
#' data (including GPS coordinates) for timestamps (rounded to the nearest minute) falling within the date ranges defined in the file names.
#'
#' @param timestamps A vector of POSIXct timestamps for which GPS coordinates and associated parameter data are to be retrieved.
#' @param ferrybox_folder A string representing the path to the folder containing Ferrybox `.txt` files.
#' @param parameters A character vector specifying the parameters to extract from the Ferrybox data. Defaults to `c("8002", "8003")`.
#' @param ship A string representing the name of the ship to filter Ferrybox files. The default is "SveaFB".
#' @param latitude_param A string specifying the header name for the latitude column in the Ferrybox data. Default is "8002".
#' @param longitude_param A string specifying the header name for the longitude column in the Ferrybox data. Default is "8003".
#'
#' @details
#' The function extracts data from files whose names match the specified ship and fall within the date ranges defined in the file names. The columns corresponding to `latitude_param` and `longitude_param` will be renamed to `gpsLatitude` and `gpsLongitude`, respectively, if they are present in the `parameters` argument.
#'
#' The function also handles cases where the exact timestamp is missing by attempting to interpolate the data using floor and ceiling rounding methods. The final output will ensure that all specified parameters are numeric.
#'
#' @return A data frame containing the input timestamps and corresponding data for the specified parameters.
#' Columns include 'timestamp', 'gpsLatitude', 'gpsLongitude' (if applicable), and the specified parameters.
#'
#' @examples
#' \dontrun{
#' ferrybox_folder <- "/path/to/ferrybox/data"
#' timestamps <- as.POSIXct(c("2016-08-10 10:47:34 UTC",
#'                            "2016-08-10 11:12:21 UTC",
#'                            "2016-08-10 11:35:59 UTC"))
#'
#' result <- ifcb_get_ferrybox_data(timestamps, ferrybox_folder)
#' print(result)
#' }
#'
#' @export
ifcb_get_ferrybox_data <- function(timestamps, ferrybox_folder, parameters = c("8002", "8003"), ship = "SveaFB", latitude_param = "8002", longitude_param = "8003") {
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
      NULL
    })

    if (!is.null(ferrybox_data_temp)) {
      ferrybox_data <- dplyr::bind_rows(ferrybox_data, ferrybox_data_temp)
    }
  }

  if (nrow(ferrybox_data) == 0) {
    stop("No valid ferrybox data could be read from the filtered files.")
  }

  # Ensure that the specified parameters exist in the data
  missing_params <- setdiff(parameters, colnames(ferrybox_data))
  if (length(missing_params) > 0) {
    stop(paste("The following parameters are missing from the ferrybox data:", paste(missing_params, collapse = ", ")))
  }

  # Extract and clean ferrybox position data
  ferrybox_position <- ferrybox_data %>%
    dplyr::mutate(
      timestamp_minute_temp = tryCatch({
        ymd_hms(as.numeric(ferrybox_data$`38059`), tz = "UTC")
      }, error = function(e) {
        stop("Error parsing ferrybox timestamp data.")
      })
    ) %>%
    dplyr::mutate(
      timestamp_minute = lubridate::round_date(timestamp_minute_temp, unit = "minute"),
      time_difference = abs(difftime(timestamp_minute_temp, timestamp_minute, units = "secs"))
    )

  # Convert parameters to numeric where applicable
  ferrybox_position <- ferrybox_position %>%
    dplyr::mutate(across(all_of(parameters), as.numeric, .names = "numeric_{col}"))

  if (nrow(ferrybox_position) == 0) {
    stop("No valid position data could be extracted from the ferrybox data.")
  }

  # Merge the ferrybox position data with the input timestamps
  output <- data.frame(timestamp = timestamps) %>%
    mutate(timestamp_minute = round_date(timestamp, unit = "minute")) %>%
    left_join(ferrybox_position, by = "timestamp_minute") %>%
    group_by(timestamp_minute) %>%
    slice_min(time_difference, with_ties = FALSE) %>% # Select the row with the smallest time difference
    ungroup() %>%
    select(timestamp, all_of(parameters))

  # Handle missing data using floor and ceiling rounding
  missing_data_floor <- handle_missing_ferrybox_data(output, ferrybox_position, parameters, floor_date)
  missing_data_ceiling <- handle_missing_ferrybox_data(output, ferrybox_position, parameters, ceiling_date)

  # Merge and coalesce missing data
  missing_data <-missing_data_floor %>%
    full_join(missing_data_ceiling, by = "timestamp") %>%
    # Dynamically coalesce columns with .x and .y suffixes
    mutate(across(
      .cols = contains(".x"),
      .fns = ~ coalesce(.x, get(gsub(".x", ".y", cur_column()))),
      .names = "{str_remove(.col, '.x')}"
    )) %>%
    select(-contains(".y"), -contains(".x"))

  # Update the output with missing data
  output <- output %>%
    left_join(missing_data, by = "timestamp") %>%
    # Dynamically coalesce columns with .x and .y suffixes
    mutate(across(
      .cols = contains(".x"),
      .fns = ~ coalesce(.x, get(gsub(".x", ".y", cur_column()))),
      .names = "{str_remove(.col, '.x')}"
    )) %>%
    select(-contains(".y"), -contains(".x"))

  # Ensure all parameters are numeric
  output <- output %>%
    mutate(across(all_of(parameters), as.numeric))

  # Check for multiple rows per minute and issue a warning
  duplicate_rows <- output %>%
    dplyr::group_by(timestamp) %>%
    dplyr::summarize(n = n()) %>%
    dplyr::filter(n > 1)

  if (nrow(duplicate_rows) > 0) {
    warning("Multiple rows detected for the following minute timestamps: ",
            paste(duplicate_rows$timestamp, collapse = ", "))
  }

  # Check if latitude_param and longitude_param are in parameters and rename accordingly
  names(output)[names(output) == latitude_param] <- ifelse(latitude_param %in% parameters, "gpsLatitude", names(output)[names(output) == latitude_param])
  names(output)[names(output) == longitude_param] <- ifelse(longitude_param %in% parameters, "gpsLongitude", names(output)[names(output) == longitude_param])

  return(output)
}
