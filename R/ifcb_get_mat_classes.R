#' Get Classes from a MAT File
#'
#' This function reads a .mat file containing class information and extracts the list of classes.
#'
#' @param mat_file A character string specifying the path to the .mat file containing class information.
#' @param variable_name A character string specifying the variable name in the .mat file that contains the class information.
#'                      Default is "class2use". Other examples are class2use.manual from a manual file, or class2use.auto for an
#'                      classlist used for automatic assignment. This parameter can be found using `get_variable_names_from_mat`.
#' @return A character vector of class names.
#' @examples
#' \dontrun{
#' # Get class names from a class2use file
#' classes <- ifcb_get_classes("path/to/class2use.mat", "class2use")
#' print(classes)
#'
#' # Get class names from a classifier file
#' classes <- ifcb_get_classes("path/to/classifier.mat", "classes")
#' print(classes)
#' }
#' @import R.matlab
#' @export
#' @seealso \code{\link{get_variable_names_from_mat}}
ifcb_get_mat_classes <- function(mat_file, variable_name = "class2use") {
  # Read class information from MAT file
  class_info <- R.matlab::readMat(mat_file)

  # Extract classes using the specified variable name
  if (!variable_name %in% names(class_info)) {
    stop("Variable name not found in MAT file")
  }

  classes <- unlist(class_info[[variable_name]])

  return(classes)
}
