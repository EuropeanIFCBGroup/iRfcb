#' Read Feature Files from a Specified Folder
#'
#' This function reads feature files from a given folder, filtering them optionally
#' based on whether they are multiblob or single blob files.
#'
#' @param feature_folder Path to the folder containing feature files.
#' @param multiblob Logical indicating whether to filter for multiblob files (default: FALSE).
#'
#' @return A named list of data frames, where each element corresponds to a feature file read from \code{feature_folder}.
#'   The list is named with the base names of the feature files.
#'
#' @examples
#' \dontrun{
#' # Read feature files from a folder
#' features <- ifcb_read_features("path/to/feature_folder")
#'
#' # Read only multiblob feature files
#' multiblob_features <- ifcb_read_features("path/to/feature_folder", multiblob = TRUE)
#' }
#'
#' @importFrom utils read.csv
#' @importFrom stats setNames
#'
#' @export
ifcb_read_features <- function(feature_folder, multiblob = FALSE) {

  feature_files <- list.files(feature_folder, pattern = "D.*\\.csv", full.names = TRUE, recursive = TRUE)

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
