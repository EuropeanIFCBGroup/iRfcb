#' Get Variable Names from a MAT File
#'
#' This function reads a .mat file and retrieves the names of all variables stored within it.
#'
#' @param mat_file A character string specifying the path to the .mat file.
#' @return A character vector of variable names.
#' @examples
#' \dontrun{
#' # Get variable names from a MAT file
#' variables <- get_variable_names_from_mat("path/to/file.mat")
#' print(variables)
#' }
#' @import R.matlab
#' @export
#' @seealso \code{\link{get_classes_from_mat}}
get_variable_names_from_mat <- function(mat_file) {
  # Read the contents of the MAT file
  mat_contents <- R.matlab::readMat(mat_file)

  # Extract variable names
  variable_names <- names(mat_contents)

  return(variable_names)
}
