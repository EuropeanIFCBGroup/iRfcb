#' Download Test IFCB Data
#'
#' This function downloads a zip archive containing MATLAB files from the `iRfcb`
#' dataset available in the SMHI IFCB Plankton Image Reference Library (Torstensson et al. 2024),
#' unzips them into the specified folder and extracts png images. These data can be used, for instance,
#' for testing `iRfcb` and for creating the tutorial vignette
#' using \code{vignette("introduction", package = "iRfcb")}
#'
#' @param dest_dir The destination directory where the files will be unzipped.
#' @param figshare_article The file article number at the SciLifeLab Figshare data repository.
#' By default, the `iRfcb` test dataset (48158716) from Torstensson et al. (2024) is used.
#' @param max_retries The maximum number of retry attempts in case of download failure. Default is 3.
#' @param sleep_time The sleep time between download attempts, in seconds. Default is 10.
#' @param keep_zip A logical indicating whether to keep the downloaded zip archive after its download. Default is FALSE.
#' @param verbose A logical indicating whether to print progress messages. Default is TRUE.
#' @param expected_checksum `r lifecycle::badge("deprecated")`
#'   Optional. The expected MD5 checksum of the downloaded zip file.
#'   If not provided, it is automatically looked up from an internal table based on
#'   \code{figshare_article}.
#'
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
ifcb_download_test_data <- function(dest_dir, figshare_article = "48158716", max_retries = 3, sleep_time = 10, keep_zip = FALSE, verbose = TRUE, expected_checksum = deprecated()) {
  # Warn the user if adc_folder is used
  if (lifecycle::is_present(expected_checksum)) {
    # Signal the deprecation to the user
    deprecate_warn("0.7.0", "iRfcb::ifcb_download_test_data(expected_checksum = )")
  }

  urls <- c(paste0("https://figshare.com/ndownloader/files/", figshare_article))

  if (figshare_article == "48158716") {
    urls <- c(urls,
              paste0("https://raw.githubusercontent.com/EuropeanIFCBGroup/iRfcb/63f2aabccade90f52b595e241a13708620629c42/data-raw/", figshare_article, ".zip"))
  }

  if (!dir.exists(dest_dir)) dir.create(dest_dir, recursive = TRUE)
  dest_file <- file.path(dest_dir, paste0(figshare_article, ".zip"))

  # Use existing zip if present, otherwise download
  if (file.exists(dest_file)) {
    if (verbose) {
      message("Using existing zip file: ", dest_file)
    }
  } else {
    downloaded <- FALSE
    for (url in urls) {
      if (verbose) message("Attempting download from: ", url)
      attempts <- 0
      while (attempts < max_retries && !downloaded) {
        attempts <- attempts + 1
        tryCatch({
          curl::curl_download(url, dest_file, quiet = TRUE, mode = "wb")
          if (!file.exists(dest_file) || file.info(dest_file)$size == 0) {
            stop("Downloaded file is empty")
          }
          downloaded <- TRUE
        }, error = function(e) {
          if (verbose) {
            message("Attempt ", attempts, " failed. Retrying in ", sleep_time, " s")
          }
          Sys.sleep(sleep_time)
        })
      }
      if (downloaded) break
    }

    if (!downloaded) {
      unlink(dest_file)
      stop("Download failed from all sources after ", max_retries, " attempts each.")
    }
  }

  # Unzip the file into the appropriate subdirectory
  unzip(dest_file, exdir = dest_dir)

  # Remove the downloaded zip file
  if (!keep_zip) {
    file.remove(dest_file)
  }

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
