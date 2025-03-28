#' Download and Extract WHOI-Plankton Data
#'
#' This function downloads WHOI-Plankton annotated plankton images for specified years
#' from \url{https://hdl.handle.net/1912/7341}.
#' The extracted `.png` files are saved in the specified destination folder.
#'
#' @param years A vector of years (numeric or character) indicating which datasets to download.
#' @param dest_folder A string specifying the destination folder where the files will be extracted.
#'
#' @return No return value. Files are downloaded and extracted to `dest_folder`.
#' @examples
#' \dontrun{
#' ifcb_download_whoi_plankton(c(2006, 2007), "data/")
#' }
#' @export
ifcb_download_whoi_plankton <- function(years, dest_folder) {
  # Define the URL mapping
  url_map <- list(
    "2006" = "https://darchive.mblwhoilibrary.org/bitstreams/6968c380-3713-57b1-bdca-5b21e514a996/download",
    "2007" = "https://darchive.mblwhoilibrary.org/bitstreams/ff635112-6337-5b34-9354-4035847dae24/download",
    "2008" = "https://darchive.mblwhoilibrary.org/bitstreams/c9bf8e43-fa1c-5fd7-9328-04598db52c2e/download",
    "2009" = "https://darchive.mblwhoilibrary.org/bitstreams/18b14b5a-2a68-5f85-845f-1c1591a8f1a6/download",
    "2010" = "https://darchive.mblwhoilibrary.org/bitstreams/7d6bd792-3fad-59aa-8906-af1fb377115e/download",
    "2011" = "https://darchive.mblwhoilibrary.org/bitstreams/c1b63530-b104-5a1f-a8b3-f55898f788e7/download",
    "2012" = "https://darchive.mblwhoilibrary.org/bitstreams/67fd1c6a-9268-58f6-808d-a757bf49a345/download",
    "2013" = "https://darchive.mblwhoilibrary.org/bitstreams/e1fd23e9-1b79-51a8-a165-1f9bb30177d8/download",
    "2014" = "https://darchive.mblwhoilibrary.org/bitstreams/5bf89ef0-0155-5ac2-923b-f2a8578c963a/download"
  )

  # Ensure the destination folder exists
  if (!dir.exists(dest_folder)) {
    dir.create(dest_folder, recursive = TRUE)
  }

  for (year in years) {
    year <- as.character(year)
    if (year %in% names(url_map)) {
      zip_file <- file.path(dest_folder, paste0(year, ".zip"))

      # Download the file using curl package
      message("Downloading WHOI Plankton ", year, "...")
      handle <- curl::new_handle()
      curl::curl_download(url_map[[year]], zip_file, handle = handle)

      # Extract the file
      message("Extracting ", year, "...")
      unzip(zip_file, exdir = dest_folder)

      # Remove the zip file after extraction
      file.remove(zip_file)
    } else {
      message("Skipping year ", year, ": No URL found.")
    }
  }
  message("Download and extraction complete.")
}
