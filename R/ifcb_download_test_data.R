#' Download test IFCB data
#'
#' This function downloads two zip archives containing .png images and MATLAB files from the `svea_skagerrak_kattegat`
#' dataset available in the SMHI IFCB plankton image reference library (Torstensson et al. 2024), and unzips them into the
#' specified folder. These data can, for instance, be used for testing `iRfcb`.
#'
#' @param dest_dir The destination directory where the files will be unzipped.
#' @param method Method to be used for downloading files. Current download methods are "internal",
#' "libcurl", "wget", "curl" and "wininet" (Windows only), and there is a value "auto":
#' see ‘utils::download.file’.
#'
#' @references Torstensson, Anders; Skjevik, Ann-Turi; Mohlin, Malin; Karlberg, Maria; Karlson, Bengt (2024). SMHI IFCB plankton image reference library. SciLifeLab. Dataset.
#' \href{https://doi.org/10.17044/scilifelab.25883455.v2}{https://doi.org/10.17044/scilifelab.25883455.v2}
#'
#' @importFrom utils download.file
#' @examples
#' \dontrun{
#' # Download and unzip IFCB test data into the "data" directory
#' ifcb_download_test_data("data")
#' }
#'
#' @export
ifcb_download_test_data <- function(dest_dir, method = "auto") {
  # URLs of the zip files
  urls <- c(
    "https://figshare.scilifelab.se/ndownloader/files/46770265",
    "https://figshare.scilifelab.se/ndownloader/files/46770013"
  )

  # Subdirectories for the extracted contents
  subdirs <- c(
    dest_dir,
    file.path(dest_dir, "png")
  )

  # Create destination directories if they do not exist
  for (subdir in subdirs) {
    if (!dir.exists(subdir)) {
      dir.create(subdir, recursive = TRUE)
    }
  }

  for (i in seq_along(urls)) {
    url <- urls[i]
    subdir <- subdirs[i]

    # Determine the local destination file path
    dest_file <- file.path(dest_dir, basename(url))

    # Download the file
    download.file(url, dest_file, method = method, quiet = FALSE, mode = "wb",
                  cacheOK = FALSE, extra = getOption("download.file.extra"),
                  headers = c(From = "noreply@example.com"))

    # Unzip the file into the appropriate subdirectory
    unzip(dest_file, exdir = subdir)

    # Remove the downloaded zip file
    file.remove(dest_file)
  }

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
  dest_class_file <- file.path(classified_dir, "D20230810T113059_IFCB134_class_v1.mat")
  dest_summary_file <- file.path(summary_dir, "summary_allTB_2023.mat")
  dest_correction_file <- file.path(manual_dir, "Alexandrium_pseudogonyaulax_selected_images.txt")
  dest_ferrybox_file <- file.path(ferrybox_dir, "SveaFB_38059_20220501000100_20220531235800_OK.txt")

  # Copy files to their respective destinations
  file.copy(class_file, dest_class_file)
  file.copy(summary_file, dest_summary_file)
  file.copy(correction_file, dest_correction_file)
  file.copy(ferrybox_file, dest_ferrybox_file)

  cat("Download and extraction complete.\n")
}
