#' Get Variable Names from a MAT File
#'
#' This function reads a .mat file generated the `ifcb-analysis` repository (Sosik and Olson 2007) and retrieves the
#' names of all variables stored within it.
#'
#' @param mat_file A character string specifying the path to the .mat file.
#' @param use_python Logical. If `TRUE`, attempts to read the `.mat` file using a Python-based method. Default is `FALSE`.
#'
#' @details
#' If `use_python = TRUE`, the function tries to read the `.mat` file using `ifcb_read_mat()`, which relies on `SciPy`.
#' This approach may be faster than the default approach using `R.matlab::readMat()`, especially for large `.mat` files.
#' To enable this functionality, ensure Python is properly configured with the required dependencies.
#' You can initialize the Python environment and install necessary packages using `ifcb_py_install()`.
#'
#' If `use_python = FALSE` or if `SciPy` is not available, the function falls back to using `R.matlab::readMat()`.
#'
#' @return A character vector of variable names.
#' @examples
#' \dontrun{
#' # Get variable names from a MAT file
#' variables <- ifcb_get_mat_names("path/to/file.mat")
#' print(variables)
#' }
#' @export
#' @references Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
#' @seealso \code{\link{ifcb_get_mat_variable}} \url{https://github.com/hsosik/ifcb-analysis}
ifcb_get_mat_names <- function(mat_file, use_python = FALSE) {
  if (use_python && scipy_available()) {
    mat_contents <- ifcb_read_mat(mat_file)
  } else {
    # Read the contents of the MAT file
    mat_contents <- read_mat(mat_file, fixNames = FALSE)
  }

  # Extract variable names
  variable_names <- names(mat_contents)

  variable_names
}
