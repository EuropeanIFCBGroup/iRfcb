utils::globalVariables("Name")
#' Download and Extract WHOI-Plankton Data
#'
#' This function downloads WHOI-Plankton annotated plankton images (Sosik et al. 2015) for specified years
#' from \url{https://hdl.handle.net/1912/7341}.
#' The extracted `.png` data are saved in the specified destination folder.
#'
#' @param years A vector of years (numeric or character) indicating which datasets to download. The available years are currently 2006 to 2014.
#' @param dest_folder A string specifying the destination folder where the files will be extracted.
#' @param extract_images Logical. If `TRUE`, extracts `.png` images from the downloaded archives and removes the `.zip` files.
#'   If `FALSE`, only downloads the archives without extracting images. Default is `TRUE`.
#' @param max_retries An integer specifying the maximum number of attempts to retrieve data. Default is 10.
#' @param quiet Logical. If TRUE, suppresses messages about the progress and completion of the download process. Default is FALSE.
#'
#' @return If `extract_images = FALSE`, returns a data frame containing metadata of downloaded image files.
#'   Otherwise, no return value; files are downloaded and extracted to `dest_folder`.
#'
#' @examples
#' \dontrun{
#' # Download and extract images for 2006 and 2007 in the data folder
#' ifcb_download_whoi_plankton(c(2006, 2007),
#'                             "data",
#'                             extract_images = TRUE)
#' }
#'
#' @references Sosik, H. M., Peacock, E. E. and Brownlee E. F. (2015), Annotated Plankton Images - Data Set for Developing and Evaluating Classification Methods. \doi{10.1575/1912/7341}
#'
#' @export
ifcb_download_whoi_plankton <- function(years, dest_folder, extract_images = TRUE, max_retries = 10, quiet = FALSE) {
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

  # Convert the list to a dataframe
  url_df <- data.frame(
    year = names(url_map),
    url = unlist(url_map),
    zip_files = file.path(dest_folder, paste0(names(url_map), ".zip")),
    row.names = NULL
  )

  # Convert years to character
  years <- as.character(years)

  # Check if the specified years are available
  not_available <- years[!years %in% url_df$year]

  # Filter the years to only include those available
  years <- years[years %in% url_df$year]

  # Filter the dataframe to only include the specified years
  url_df <- url_df %>%
    filter(year %in% years)

  # Copy the original dataframe for later use
  url_df_all <- url_df

  # Check if any valid years are specified
  if (nrow(url_df) == 0) {
    stop("No valid years specified.")
  }

  # Warn if any years are not available
  if (length(not_available) > 0) {
    warning("Skipping year(s) ", paste(not_available, collapse = ", "), ": No URL found.")
  }

  # Ensure the destination folder exists
  if (!dir.exists(dest_folder)) {
    dir.create(dest_folder, recursive = TRUE)
  }

  # Retry logic
  attempt <- 1
  success <- FALSE

  while (attempt <= max_retries && !success) {
    if (!quiet) message("Downloading WHOI-Plankton images from year(s):\n", paste(url_df$year, collapse = ", "), " (Attempt ", attempt, ")...")

    # Perform the download with multi_download()
    res <- curl::multi_download(
      urls = url_df$url,
      destfiles = url_df$zip_files,
      resume = TRUE, # Enable resuming
      progress = !quiet, # Show progress if not quiet
      multiplex = TRUE
    )

    # Split the results into complete and incomplete downloads
    complete <- res %>%
      filter(success)

    # Check if all downloads were successful
    incomplete <- res %>%
      filter(!success)

    # Check results
    if (nrow(incomplete) == 0) {
      if (!quiet) message("Download completed for year(s):\n", paste(years, collapse = ", "))
      success <- TRUE
    } else {
      url_df_complete <- dplyr::filter(url_df, basename(dirname(url)) %in% basename(dirname(complete$url)))
      url_df <- dplyr::filter(url_df, basename(dirname(url)) %in% basename(dirname(incomplete$url)))
      if (!quiet && nrow(url_df_complete) > 0) message("Download successful for year(s):\n", paste(url_df_complete$year, collapse = ", "))
      if (!quiet) message("Download interrupted for year(s):\n", paste(url_df$year, collapse = ", "), "\nRetrying...")
      attempt <- attempt + 1
    }
  }

  if (!extract_images) {
    # Create an empty dataframe
    output <- data.frame()

    # Extract the files
    for (yr in years) {
      # Filter the dataframe to only include the specified year
      url_df_year <- url_df_all %>%
        filter(year == yr)

      # List files
      file_list <- utils::unzip(url_df_year$zip_files, list = TRUE)

      # Filter images only
      file_list <- dplyr::filter(file_list, grepl(".png", Name))

      # Create a data frame with image info
      file_df <- data.frame(
        year = yr,
        folder = basename(dirname(file_list$Name)),
        image = file.path(dest_folder, file_list$Name),
        row.names = NULL
      )

      # Define path
      output_path <- file.path(dest_folder, yr, "images.txt")

      if (!dir.exists(dirname(output_path))) {
        dir.create(dirname(output_path), recursive = TRUE)
      }

      # Store image data for later use
      write.table(file_df, output_path, na = "", sep = "\t", quote = FALSE, row.names = FALSE)

      # Append to all years
      output <- rbind(output, file_df)
    }
    return(output)
  } else {
    # Extract the files
    for (yr in years) {

      # Filter the dataframe to only include the specified year
      url_df_year <- url_df_all %>%
        filter(year == yr)

      # Extract if the download was successful
      if (file.exists(url_df_year$zip_files)) {
        if (!quiet) message("Extracting .png images from year ", yr, "...")
        unzip(url_df_year$zip_files, exdir = dest_folder)
        file.remove(url_df_year$zip_files) # Remove zip file after extraction
      }
    }
  }
  if (!quiet) message("Download and extraction complete.")
}
