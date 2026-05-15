#' Download bin list from the IFCB Dashboard API
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' The `api/list_bins` endpoint was removed from the upstream IFCB Dashboard
#' (\href{https://github.com/WHOIGit/ifcbdb/commit/8c5839f1}{WHOIGit/ifcbdb@8c5839f1},
#' 2026-03-08), so this function no longer works against the WHOI dashboard and
#' other deployments tracking upstream. Use [ifcb_download_dashboard_metadata()]
#' instead, which retrieves the same per-bin information from the still-supported
#' `api/export_metadata` endpoint.
#'
#' @param base_url Character. Base URL to the IFCB Dashboard
#'   (e.g. "https://ifcb-data.whoi.edu/").
#' @param dataset_name Optional character. Dataset slug (e.g. "mvco") to retrieve metadata for a specific dataset.
#' If NULL, all available metadata are downloaded.
#' @param quiet Logical. If TRUE, suppresses progress messages. Default is FALSE.
#'
#' @return A data frame containing the bin list returned by the API.
#' @examples
#' \dontrun{
#'   # Deprecated: the upstream IFCB Dashboard removed `api/list_bins` on 2026-03-08.
#'   bins <- ifcb_list_dashboard_bins("https://ifcb-data.whoi.edu/",
#'                                    dataset_name = "mvco")
#'   head(bins)
#' }
#'
#' @seealso [ifcb_download_dashboard_data()] to download data from the IFCB Dashboard API.
#' @seealso [ifcb_download_dashboard_metadata()] to retrieve metadata from the IFCB Dashboard API.
#'
#' @export
ifcb_list_dashboard_bins <- function(base_url, dataset_name = NULL, quiet = FALSE) {
  lifecycle::deprecate_warn(
    when = "0.9.0",
    what = "ifcb_list_dashboard_bins()",
    with = "ifcb_download_dashboard_metadata()",
    details = "The upstream IFCB Dashboard removed the `api/list_bins` endpoint on 2026-03-08."
  )

  # Ensure base_url has no trailing slash
  base_url <- sub("/+$", "", base_url)

  # Construct full API URL
  api_url <- paste0(base_url, "/api/list_bins")

  if (!is.null(dataset_name) && nzchar(dataset_name)) {
    dataset_name <- utils::URLencode(dataset_name, reserved = TRUE)
    api_url <- paste0(api_url, "?dataset=", dataset_name)
  }

  if (!quiet) cli_inform("Fetching bin list from {.url {api_url}}")

  # Perform GET request with curl
  response <- tryCatch(
    curl::curl_fetch_memory(api_url, handle = curl::new_handle(httpheader = c(Accept = "application/json"))),
    error = function(e) cli_abort("Failed to connect to IFCB Dashboard API: {e$message}")
  )

  # Check status code
  if (response$status_code != 200) {
    cli_abort("API request failed [{response$status_code}]: {.url {api_url}}")
  }

  # Convert raw JSON to text
  json_content <- rawToChar(response$content)
  Encoding(json_content) <- "UTF-8"

  # Parse JSON
  parsed_data <- tryCatch(
    jsonlite::fromJSON(json_content, flatten = TRUE),
    error = function(e) cli_abort("Failed to parse JSON content: {e$message}")
  )

  # Convert to tibble
  df <- as_tibble(parsed_data[[1]])

  if (!quiet) cli_alert_success("Retrieved {nrow(df)} bin{?s}.")

  df
}
