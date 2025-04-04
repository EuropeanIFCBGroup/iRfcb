utils::globalVariables("r_read_mat_file")
#' Read a MATLAB .mat File in R
#'
#' This function reads a MATLAB `.mat` file using a Python function via `reticulate`.
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

  # Check if the file exists
  if (!file.exists(file_path)) {
    stop("File does not exist: ", file_path)
  }

  # Load Python script
  reticulate::source_python(system.file("python", "read_mat_file.py", package = "iRfcb"))

  # Call the Python function
  py_data <- r_read_mat_file(file_path)

  # Converts lists to matrices to ressemble R.matlab::readMat
  convert_lists_to_matrix <- function(x) {
    lapply(x, function(el) {
      if (is.list(el)) {
        # Convert 1x1 list to 1x1 matrix if it's a scalar string
        if (length(el) == 1 && is.character(el[[1]])) {
          matrix(el[[1]], nrow = 1, ncol = 1)
        }
      } else {
        el
      }
    })
  }

  # Convert Python lists to R matrices where appropriate
  convert_lists_to_matrix(py_data)
}
