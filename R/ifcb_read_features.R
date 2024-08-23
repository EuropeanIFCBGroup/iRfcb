#' Read Feature Files from a Specified Folder or File Paths
#'
#' This function reads feature files from a given folder or a specified set of file paths,
#' optionally filtering them based on whether they are multiblob or single blob files.
#'
#' @param feature_files A path to a folder containing feature files or a character vector of file paths.
#' @param multiblob Logical indicating whether to filter for multiblob files (default: FALSE).
#' @param feature_folder
#'    `r lifecycle::badge("deprecated")`
#'
#'    Use \code{feature_files} instead.
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
#' # Read feature files from a list of file paths
#' features <- ifcb_read_features(c("path/to/file1.csv", "path/to/file2.csv"))
#' }
#'
#' @importFrom utils read.csv
#' @importFrom stats setNames
#'
#' @export
ifcb_read_features <- function(feature_files = NULL, multiblob = FALSE, feature_folder = NULL) {

  # Warn the user if feature_folder is used
  if (!is.null(feature_folder)) {
    warning("'feature_folder' is deprecated. Use 'feature_files' instead.")
    feature_files <- feature_folder
  }

  # Check if feature_files is a single folder path or a vector of file paths
  if (length(feature_files) == 1 && file.info(feature_files)$isdir) {
    feature_files <- list.files(feature_files, pattern = "D.*\\.csv", full.names = TRUE, recursive = TRUE)
  }

  # Filter based on multiblob or single blob
  if (multiblob) {
    feature_files <- feature_files[grepl("multiblob", feature_files)]
  } else {
    feature_files <- feature_files[!grepl("multiblob", feature_files)]
  }

  # Initialize a named list to hold the data frames
  feature <- setNames(vector("list", length(feature_files)), basename(feature_files))

  # Loop through each file and store its contents in the feature list
  for (i in seq_along(feature_files)) {
    feature[[basename(feature_files[i])]] <- read.csv(feature_files[i])
  }

  return(feature)
}
