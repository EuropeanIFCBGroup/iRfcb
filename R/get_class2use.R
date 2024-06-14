#' Get Classes from Class2use File
#'
#' This function reads a .mat file containing class information and extracts the list of classes.
#'
#' @param class2use_file A character string specifying the path to the .mat file containing class information.
#' @return A character vector of class names.
#' @examples
#' \dontrun{
#' # Get class names from a class2use file
#' classes <- get_class2use("path/to/class2use.mat")
#' print(classes)
#' }
#' @import R.matlab
#' @export
get_class2use <- function(class2use_file) {
  # Read class information from MAT file
  class2use <- R.matlab::readMat(class2use_file)

  # Extract classes
  classes <- unlist(class2use$class2use)

  return(classes)
}
