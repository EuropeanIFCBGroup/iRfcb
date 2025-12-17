#' Read Feature Files from a Specified Folder or File Paths
#'
#' This function reads feature files from a given folder or a specified set of file paths,
#' optionally filtering them based on whether they are multiblob or single blob files.
#'
#' @param feature_files A path to a folder containing feature files or a character vector of file paths.
#' @param multiblob Logical indicating whether to filter for multiblob files (default: FALSE).
#' @param feature_version Optional numeric or character version to filter feature files by (e.g. 2 for "_v2"). Default is NULL (no filtering).
#' @param biovolume_only Logical; if TRUE, only a minimal set of feature columns
#'   required for biovolume calculations are read from each feature file
#'   (typically `roi_number` and `biovolume`). This substantially reduces
#'   memory usage and improves performance when other features are not needed.
#'   If FALSE, all available feature columns are read.
#' @param verbose Logical. Whether to display progress information. Default is TRUE.
#'
#' @return A named list of data frames, where each element corresponds to a feature file read from \code{feature_files}.
#'   The list is named with the base names of the feature files.
#'
#' @examples
#' \dontrun{
#' # Read feature files from a folder
#' features <- ifcb_read_features("path/to/feature_folder")
#'
#' # Read only multiblob feature files
#' multiblob_features <- ifcb_read_features("path/to/feature_folder", multiblob = TRUE)
#'
#' # Read only version 4 feature files
#' v4_features <- ifcb_read_features("path/to/feature_folder", feature_version = 4)
#'
#' # Read feature files from a list of file paths
#' features <- ifcb_read_features(c("path/to/file1.csv", "path/to/file2.csv"))
#' }
#'
#' @export
ifcb_read_features <- function(feature_files = NULL,
                               multiblob = FALSE,
                               feature_version = NULL,
                               biovolume_only = FALSE,
                               verbose = TRUE) {

  # Check if feature_files is a single folder path or a vector of file paths
  if (length(feature_files) == 1 && dir.exists(feature_files)) {
    feature_files <- list.files(feature_files, pattern = "D.*\\.csv", full.names = TRUE, recursive = TRUE)
  }

  # Filter based on multiblob or single blob
  if (multiblob) {
    feature_files <- feature_files[grepl("multiblob", feature_files, ignore.case = TRUE)]
  } else {
    feature_files <- feature_files[!grepl("multiblob", feature_files, ignore.case = TRUE)]
  }

  # Filter by feature version if specified
  if (!is.null(feature_version)) {
    version_pattern <- paste0("_v", feature_version, "\\.csv$")
    feature_files <- feature_files[grepl(version_pattern, feature_files)]
  }

  # Initialize a named list to hold the data frames
  feature <- setNames(vector("list", length(feature_files)), basename(feature_files))
  n_features <- length(feature_files)

  # Set up the progress bar
  if (verbose && n_features > 0) pb <- txtProgressBar(min = 0, max = n_features, style = 3)

  # Loop through each file and store its contents in the feature list
  for (i in seq_along(feature_files)) {
    if (verbose && n_features > 0) setTxtProgressBar(pb, i)
    feature[[basename(feature_files[i])]] <-
      if (biovolume_only) {
        read_csv(
          feature_files[i],
          col_select = c(roi_number, Biovolume),
          progress = FALSE,
          col_types = cols()
        )
      } else {
        read_csv(
          feature_files[i],
          progress = FALSE,
          col_types = cols()
        )
      }
  }

  # Close the progress bar
  if (verbose && n_features > 0) close(pb)

  feature
}
