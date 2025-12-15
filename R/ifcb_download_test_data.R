#' Download Test IFCB Data
#'
#' This function downloads a zip archive containing MATLAB files from the `iRfcb`
#' dataset available in the SMHI IFCB Plankton Image Reference Library (Torstensson et al. 2024),
#' unzips them into the specified folder and extracts png images. These data can be used, for instance,
#' for testing `iRfcb` and for creating the tutorial vignette
#' using \code{vignette("a-general-tutorial", package = "iRfcb")}
#'
#' @param dest_dir The destination directory where the files will be unzipped.
#' @param figshare_article The file article number at the SciLifeLab Figshare data repository.
#' By default, the `iRfcb` test dataset (48158716) from Torstensson et al. (2024) is used.
#' @param expected_checksum Optional. The expected MD5 checksum of the downloaded zip file.
#'   If not provided, it is automatically looked up from an internal table based on
#'   \code{figshare_article}.
#' @param max_retries The maximum number of retry attempts in case of download failure. Default is 5.
#' @param sleep_time The sleep time between download attempts, in seconds. Default is 10.
#' @param keep_zip A logical indicating whether to keep the downloaded zip archive after its download. Default is FALSE.
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
ifcb_download_test_data <- function(dest_dir, figshare_article = "48158716", expected_checksum = NULL, max_retries = 5, sleep_time = 10, keep_zip = FALSE, verbose = TRUE) {
  # Resolve expected checksum from internal lookup if not provided
  if (is.null(expected_checksum)) {
    if (figshare_article %in% names(.ifcb_checksums)) {
      expected_checksum <- .ifcb_checksums[[figshare_article]]
    } else {
      if (verbose) {
        message("No checksum available for article ", figshare_article,
                ". Proceeding without checksum verification.")
      }
      expected_checksum <- NA
    }
  }

  url <- paste0("https://figshare.scilifelab.se/ndownloader/files/", figshare_article)
  if (!dir.exists(dest_dir)) dir.create(dest_dir, recursive = TRUE)
  dest_file <- file.path(dest_dir, paste0(basename(url), ".zip"))

  # Retry download loop
  attempts <- 0
  file_valid <- FALSE
  while (attempts < max_retries && !file_valid) {
    attempts <- attempts + 1

    # Only check checksum if we have one
    if (!is.na(expected_checksum) && file.exists(dest_file)) {
      actual_checksum <- tools::md5sum(dest_file)[[1]]
      if (identical(actual_checksum, expected_checksum)) {
        file_valid <- TRUE
        break
      } else {
        if (verbose) {
          message("Checksum mismatch (attempt ", attempts, "): ", actual_checksum,
                  ". Downloading again...")
        }
        file.remove(dest_file)
      }
    }

    # Download
    tryCatch({
      curl::curl_download(url, dest_file, quiet = TRUE)
    }, error = function(e) {
      Sys.sleep(sleep_time)
    })
  }

  if (!file.exists(dest_file)) {
    stop("Download failed after ", max_retries, " attempts.")
  }

  # If checksum is available, warn if mismatch but continue
  if (!is.na(expected_checksum)) {
    actual_checksum <- tools::md5sum(dest_file)[[1]]
    if (!identical(actual_checksum, expected_checksum)) {
      if (verbose) {
        message("Final file checksum does not match expected: expected ", expected_checksum,
                " but got ", actual_checksum, ". Proceeding anyway.")
      }
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
