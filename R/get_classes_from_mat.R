#' Get Classes from a MAT File
#'
#' This function reads a .mat file containing class information and extracts the list of classes.
#'
#' @param mat_file A character string specifying the path to the .mat file containing class information.
#' @param variable_name A character string specifying the variable name in the .mat file that contains the class information.
#'                      Default is "class2use".
#' @return A character vector of class names.
#' @examples
#' \dontrun{
#' # Get class names from a class2use file
#' classes <- get_classes_from_mat("path/to/class2use.mat", "class2use")
#' print(classes)
#'
#' # Get class names from a classifier file
#' classes <- get_classes_from_mat("path/to/classifier.mat", "classes")
#' print(classes)
#' }
#' @import R.matlab
#' @export
get_classes_from_mat <- function(mat_file, variable_name = "class2use") {
  # Read class information from MAT file
  class_info <- R.matlab::readMat(mat_file)

  # Extract classes using the specified variable name
  if (!variable_name %in% names(class_info)) {
    stop("Variable name not found in MAT file")
  }

  classes <- unlist(class_info[[variable_name]])

  return(classes)
}
