#' Get Classes from Classifier File
#'
#' This function reads a .mat file containing class information and extracts the list of classes.
#'
#' @param class_file A character string specifying the path to the .mat file containing class information.
#' @return A character vector of class names.
#' @examples
#' \dontrun{
#' # Get class names from a classifier file
#' classes <- get_class2use_from_classifer("path/to/classifier.mat")
#' print(classes)
#' }
#' @import R.matlab
#' @export
get_class2use_from_classifer <- function(class_file) {
  # Read class information from MAT file
  class2use <- R.matlab::readMat(class_file)

  # Extract classes
  classes <- unlist(class2use$classes)

  return(classes)
}
