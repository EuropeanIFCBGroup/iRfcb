#' Download bin list from the IFCB Dashboard API
#'
#' @param base_url Character. Base URL to the IFCB Dashboard
#'   (e.g. "https://ifcb-data.whoi.edu/").
#' @param quiet Logical. If TRUE, suppresses progress messages. Default is FALSE.
#'
#' @return A data frame containing the bin list returned by the API.
#' @examples
#' \donttest{
#'   bins <- ifcb_list_dashboard_bins("https://ifcb-data.whoi.edu/")
#'   head(bins)
#' }
#'
#' @seealso [ifcb_download_dashboard_data()] to download data from the IFCB Dashboard API.
#' @seealso [ifcb_download_dashboard_metadata()] to retrieve metadata from the IFCB Dashboard API.
#'
#' @export
ifcb_list_dashboard_bins <- function(base_url, quiet = FALSE) {
  # Ensure base_url has no trailing slash
  base_url <- sub("/+$", "", base_url)

  # Construct full API URL
  api_url <- paste0(base_url, "/api/list_bins")

  if (!quiet) message("Fetching bin list from: ", api_url)

  # Perform GET request with curl
  response <- tryCatch(
    curl::curl_fetch_memory(api_url, handle = curl::new_handle(httpheader = c(Accept = "application/json"))),
    error = function(e) stop("Failed to connect to IFCB Dashboard API: ", e$message)
  )

  # Check status code
  if (response$status_code != 200) {
    stop("API request failed [", response$status_code, "]: ", api_url)
  }

  # Convert raw JSON to text
  json_content <- rawToChar(response$content)
  Encoding(json_content) <- "UTF-8"

  # Parse JSON
  parsed_data <- tryCatch(
    jsonlite::fromJSON(json_content, flatten = TRUE),
    error = function(e) stop("Failed to parse JSON content: ", e$message)
  )

  # Convert to tibble
  df <- as_tibble(parsed_data[[1]])

  if (!quiet) message("Successfully retrieved ", nrow(df), " bins.")

  df
}
