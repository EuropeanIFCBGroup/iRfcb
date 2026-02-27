#' Download metadata from the IFCB Dashboard API
#'
#' @param base_url Character. Base URL to the IFCB Dashboard (e.g. "https://ifcb-data.whoi.edu/").
#' @param dataset_name Optional character. Dataset slug (e.g. "mvco") to retrieve metadata for a specific dataset.
#' If NULL, all available metadata are downloaded.
#' @param quiet Logical. If TRUE, suppresses progress messages. Default is FALSE.
#'
#' @return A data frame containing the exported metadata.
#' @examples
#' \donttest{
#'   # Download metadata for a specific dataset
#'   metadata_mvco <- ifcb_download_dashboard_metadata("https://ifcb-data.whoi.edu/",
#'                                                     dataset_name = "mvco",
#'                                                     quiet = TRUE)
#'
#'   # Print result as tibble
#'   print(metadata_mvco)
#' }
#'
#' @seealso [ifcb_download_dashboard_data()] to download data from the IFCB Dashboard API.
#' @seealso [ifcb_list_dashboard_bins()] to retrieve list of available bins from the IFCB Dashboard API.
#'
#' @export
ifcb_download_dashboard_metadata <- function(base_url, dataset_name = NULL, quiet = FALSE) {
  # Ensure base_url has no trailing slash
  base_url <- sub("/+$", "", base_url)

  # Build API URL
  api_url <- paste0(base_url, "/api/export_metadata/")
  if (!is.null(dataset_name) && nzchar(dataset_name)) {
    dataset_name <- utils::URLencode(dataset_name, reserved = TRUE)
    api_url <- paste0(api_url, dataset_name)
  }

  if (!quiet) message("Fetching metadata from: ", api_url)

  # Perform GET request with curl
  response <- tryCatch(
    curl::curl_fetch_memory(api_url, handle = curl::new_handle(httpheader = c(Accept = "text/csv"))),
    error = function(e) stop("Failed to connect to IFCB Dashboard API: ", e$message)
  )

  # Check response status
  if (response$status_code != 200) {
    stop("API request failed [", response$status_code, "]: ", api_url)
  }

  # Convert raw content to UTF-8 text
  csv_content <- rawToChar(response$content)
  Encoding(csv_content) <- "UTF-8"

  # Parse CSV
  df <- tryCatch(
    readr::read_csv(I(csv_content),
                    show_col_types = FALSE,
                    progress = FALSE,
                    col_types = cols(.default = col_character())),
    error = function(e) stop("Failed to parse CSV content: ", e$message)
  )

  df <- type_convert(df,
                     col_types = cols())

  if (!quiet) {
    message("Successfully retrieved ", nrow(df), " records",
            if (!is.null(dataset_name)) paste0(" for dataset '", dataset_name, "'"), ".")
  }

  df
}
