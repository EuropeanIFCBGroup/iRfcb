utils::globalVariables("read_mat_file")
#' Read a MATLAB .mat File in R
#'
#' This function reads a MATLAB .mat file using a Python function via `reticulate`.
#'
#' @param file_path A character string representing the full path to the .mat file.
#' @return A list containing the MATLAB variables.
#'
#' @details
#' This function requires a Python interpreter with `SciPy` installed.
#'
#' @examples
#' \dontrun{
#' data <- read_mat_file_r("C:/data/sample.mat")
#' }
#'
#' @details
#' This function requires a python interpreter to be installed.
#' The required python packages can be installed in a virtual environment using `ifcb_py_install`.
#'
#' @export
#' @seealso \code{\link{ifcb_py_install}}
ifcb_read_mat <- function(file_path) {
  # Initialize python check
  check_python_and_module()

  # Load Python script
  reticulate::source_python(system.file("python", "read_mat_file.py", package = "iRfcb"))

  # Call the Python function
  read_mat_file(file_path)
}
