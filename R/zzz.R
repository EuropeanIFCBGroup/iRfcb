#' Initialize iRfcb Python Environment on Package Load
#'
#' This function is executed when the `iRfcb` package is loaded. It sets up the Python environment
#' by:
#'
#' - Reading the list of required Python packages from `requirements.txt`.
#' - Ensuring that the required Python packages are declared using `reticulate::py_require()`.
#'
#' If any required Python packages are missing, they will not be loaded,
#' and a warning may be issued when attempting to use them later.
#'
#' @param libname The name of the package library.
#' @param pkgname The name of the package.
#' @noRd
.onLoad <- function(libname, pkgname) {
  # CRAN OMP THREAD LIMIT
  Sys.setenv("OMP_THREAD_LIMIT" = 1)
  Sys.setenv("OPENBLAS_NUM_THREADS" = 1)
  Sys.setenv("MKL_NUM_THREADS" = 1)

  # Get the path to the requirements file
  req_file <- system.file("python", "requirements.txt", package = "iRfcb")

  # Check required packages
  reqs <- scan(req_file, what = character(), quiet = TRUE)

  # List required packages
  reticulate::py_require(reqs)
}
