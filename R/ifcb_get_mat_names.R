#' Get Variable Names from a MAT File
#'
#' This function reads a .mat file generated the ifcb-analysis repository and retrieves the
#' names of all variables stored within it.
#'
#' @param mat_file A character string specifying the path to the .mat file.
#' @return A character vector of variable names.
#' @examples
#' \dontrun{
#' # Get variable names from a MAT file
#' variables <- ifcb_get_mat_names("path/to/file.mat")
#' print(variables)
#' }
#' @import R.matlab
#' @export
#' @seealso \code{\link{ifcb_get_mat_variable}}  \url{https://github.com/hsosik/ifcb-analysis}
ifcb_get_mat_names <- function(mat_file) {
  # Read the contents of the MAT file
  mat_contents <- R.matlab::readMat(mat_file)

  # Extract variable names
  variable_names <- names(mat_contents)

  return(variable_names)
}
