#' Download Test IFCB Data
#'
#' This function downloads a zip archive containing MATLAB files from the `iRfcb`
#' dataset available in the SMHI IFCB Plankton Image Reference Library (Torstensson et al. 2024),
#' unzips them into the specified folder and extracts png images. These data can be used, for instance,
#' for testing iRfcb and for creating the tutorial vignette
#' using \code{vignette("a-general-tutorial", package = "iRfcb")}
#'
#' @param dest_dir The destination directory where the files will be unzipped.
#' @param figshare_article The file article number at the SciLifeLab Figshare data repository.
#' By default, the iRfcb test dataset (48158716) from Torstensson et al. (2024) is used.
#' @param max_retries The maximum number of retry attempts in case of download failure. Default is 5.
#' @param sleep_time The sleep time between download attempts, in seconds. Default is 10.
#' @param verbose A logical indicating whether to print progress messages. Default is TRUE.
#'
#' @return No return value. This function is called for its side effect of downloading, extracting, and organizing IFCB test data.
#'
#' @references Torstensson, Anders; Skjevik, Ann-Turi; Mohlin, Malin; Karlberg, Maria; Karlson, Bengt (2024). SMHI IFCB Plankton Image Reference Library. Version 3. SciLifeLab. Dataset.
#' \doi{10.17044/scilifelab.25883455.v3}
#'
#' @examples
#' \dontrun{
#' # Download and unzip IFCB test data into the "data" directory
#' ifcb_download_test_data("data")
#' }
#'
#' @export
ifcb_download_test_data <- function(dest_dir, figshare_article = "48158716", max_retries = 5, sleep_time = 10, verbose = TRUE) {
  # URL of the zip file
  url <- paste0("https://figshare.scilifelab.se/ndownloader/files/", figshare_article)

  # Create destination directories if they do not exist
  if (!dir.exists(dest_dir)) {
    dir.create(dest_dir, recursive = TRUE)
  }

  # Determine the local destination file path
  dest_file <- file.path(dest_dir, paste0(basename(url), ".zip"))

  # Initialize retry counter
  attempts <- 0
  success <- FALSE

  # Implement retry logic
  while (attempts < max_retries && !success) {
    attempts <- attempts + 1

    # browser-like UA for compatibility with CDNs
    ua <- "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/126.0.0.0 Safari/537.36"

    # 1) Ask Figshare for the download URL but DO NOT follow redirects.
    #    We use httr::GET with followlocation = FALSE to capture the Location header.
    head_resp <- tryCatch(
      httr::GET(
        url,
        httr::user_agent(ua),
        httr::accept("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"),
        httr::config(followlocation = FALSE),
        httr::timeout(60)
      ),
      error = function(e) e
    )

    if (inherits(head_resp, "error")) {
      message("Attempt ", attempts, " failed when fetching redirect: ", head_resp$message)
      if (attempts < max_retries) {
        message("Sleeping ", sleep_time, " s before retry...")
        Sys.sleep(sleep_time)
        next
      } else break
    }

    status <- httr::status_code(head_resp)
    if (status %in% c(302L, 301L)) {
      location <- httr::headers(head_resp)[["location"]]
      if (!nzchar(location)) {
        message("Attempt ", attempts, ": received redirect without Location header.")
        if (attempts < max_retries) Sys.sleep(sleep_time) else break
        next
      }

      # 2) Download the presigned S3 URL (should not require cookies)
      handle <- curl::new_handle(
        followlocation = TRUE,
        resume_from   = if (file.exists(dest_file)) file.info(dest_file)$size else 0,
        verbose       = TRUE
      )
      curl::handle_setopt(
        handle,
        useragent   = ua,
        http_version = 2L # 2L = CURL_HTTP_VERSION_1_1 in libcurl's enum (force 1.1)
      )
      # Optionally set Accept header for the download as well:
      curl::handle_setheaders(handle, "Accept" = "application/zip,application/octet-stream,*/*")

      dl_ok <- tryCatch({
        curl::curl_download(location, dest_file, handle = handle, quiet = FALSE)
        file.exists(dest_file)
      }, error = function(e) {
        message("Attempt ", attempts, " download error: ", e$message)
        FALSE
      })

      if (isTRUE(dl_ok)) {
        success <- TRUE
        message("Download succeeded on attempt ", attempts, ".")
        break
      } else {
        message("Attempt ", attempts, " failed to download presigned URL.")
        if (attempts < max_retries) Sys.sleep(sleep_time) else break
        next
      }

    } else if (status == 200L) {
      # Some servers may directly serve the content without redirect.
      message("Received 200 from ndownloader; downloading body directly.")
      handle <- curl::new_handle(
        resume_from   = if (file.exists(dest_file)) file.info(dest_file)$size else 0,
        followlocation = TRUE,
        verbose        = TRUE
      )
      curl::handle_setopt(handle, useragent = ua, http_version = 2L)
      dl_ok <- tryCatch({
        curl::curl_download(url, dest_file, handle = handle, quiet = FALSE)
        file.exists(dest_file)
      }, error = function(e) {
        message("Attempt ", attempts, " direct download error: ", e$message)
        FALSE
      })

      if (isTRUE(dl_ok)) {
        success <- TRUE
        message("Direct download succeeded on attempt ", attempts, ".")
        break
      } else {
        message("Attempt ", attempts, " direct body download failed.")
        if (attempts < max_retries) Sys.sleep(sleep_time) else break
        next
      }

    } else if (status == 403L) {
      message("Attempt ", attempts, ": server returned 403 Forbidden at ndownloader endpoint.")
      # 403 could be temporary (rate-limiting, CDN block). retry with sleep.
      if (attempts < max_retries) Sys.sleep(sleep_time) else break
      next

    } else {
      message("Attempt ", attempts, ": unexpected status ", status, " from ndownloader.")
      if (attempts < max_retries) Sys.sleep(sleep_time) else break
      next
    }
  } # end while

  if (!success) stop("Download failed after ", max_retries, " attempts. See messages above for details.")

  # Unzip the file into the appropriate subdirectory
  unzip(dest_file, exdir = dest_dir)

  # Remove the downloaded zip file
  file.remove(dest_file)

  # Extract png images
  ifcb_extract_annotated_images(file.path(dest_dir, "manual"),
                                file.path(dest_dir, "config", "class2use.mat"),
                                file.path(dest_dir, "data"),
                                file.path(dest_dir, "png"),
                                skip_class = "unclassified",
                                verbose = FALSE)

  # Define source files
  class_file <- system.file("exdata/example.mat", package = "iRfcb")
  summary_file <- system.file("exdata/example_summary.mat", package = "iRfcb")
  correction_file <- system.file("exdata/example.txt", package = "iRfcb")
  ferrybox_file <- system.file("exdata/example_ferrybox.txt", package = "iRfcb")

  # Define destination directories
  classified_dir <- file.path(dest_dir, "classified", "2023")
  summary_dir <- file.path(classified_dir, "summary")
  manual_dir <- file.path(dest_dir, "manual", "correction")
  ferrybox_dir <- file.path(dest_dir, "ferrybox_data")

  # Create necessary directories
  dir.create(summary_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(manual_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(ferrybox_dir, recursive = TRUE, showWarnings = FALSE)

  # Define destination files
  dest_class_file <- file.path(classified_dir, "D20230314T001205_IFCB134_class_v1.mat")
  dest_summary_file <- file.path(summary_dir, "summary_allTB_2023.mat")
  dest_correction_file <- file.path(manual_dir, "Alexandrium_pseudogonyaulax_selected_images.txt")
  dest_ferrybox_file <- file.path(ferrybox_dir, "SveaFB_38059_20220501000100_20220531235800_OK.txt")

  # Copy files to their respective destinations
  file.copy(class_file, dest_class_file)
  file.copy(summary_file, dest_summary_file)
  file.copy(correction_file, dest_correction_file)
  file.copy(ferrybox_file, dest_ferrybox_file)

  if (verbose) {
    cat("Download and extraction complete.\n")
  }
}
