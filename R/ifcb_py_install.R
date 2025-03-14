#' Install iRfcb Python Environment
#'
#' This function sets up the Python environment for `iRfcb`. By default, it creates and activates a Python virtual environment (`venv`) named "iRfcb" and installs the required Python packages from the "requirements.txt" file.
#' Alternatively, users can opt to use the system Python instead of creating a virtual environment by setting `use_venv = FALSE`.
#'
#' @param envname A character string specifying the name of the virtual environment to create. Default is ".virtualenvs/iRfcb".
#' @param use_venv Logical. If `TRUE` (default), a virtual environment is created. If `FALSE`, the system Python is used instead, and missing packages are installed globally for the user.
#' @param packages A character vector of additional Python packages to install. If NULL (default), only the packages from "requirements.txt" are installed.
#'
#' @return No return value. This function is called for its side effect of configuring the Python environment.
#'
#' @examples
#' \dontrun{
#' # Install the iRfcb Python environment using a virtual environment (default)
#' ifcb_py_install()
#'
#' # Install the iRfcb Python environment with additional packages
#' ifcb_py_install(packages = c("numpy", "plotly"))
#'
#' # Use system Python instead of a virtual environment
#' ifcb_py_install(use_venv = FALSE)
#' }
#' @export
ifcb_py_install <- function(envname = ".virtualenvs/iRfcb", use_venv = TRUE, packages = NULL) {
  # Get the path to the requirements file
  req_file <- system.file("python", "requirements.txt", package = "iRfcb")

  if (!file.exists(req_file)) {
    stop("Requirements file not found: ", req_file)
  }

  # If use_venv is FALSE, use system Python
  if (!use_venv) {
    message("Using system Python instead of a virtual environment.")

    # Dynamically discover system Python executable
    py_config <- reticulate::py_discover_config()
    python_path <- py_config$python

    if (is.null(python_path)) {
      stop("Could not find a valid Python interpreter. Please ensure Python is installed.")
    }

    # Use the discovered Python path
    reticulate::use_python(python_path, required = TRUE)

    # Read required packages from requirements.txt
    required_packages <- scan(req_file, what = character(), quiet = TRUE)

    # Combine required packages with additional ones
    all_packages <- unique(c(required_packages, packages))

    # Declare Python Requirements
    reticulate::py_require(required_packages)

    # Initialize python
    temp <- py_available(initialize = TRUE)
  } else {
    # Otherwise, create or use the virtual environment
    if (!reticulate::virtualenv_exists(envname)) {
      message("Creating virtual environment: ", envname)
      if (!is.null(packages)) {
        reticulate::virtualenv_create(envname, requirements = req_file, quiet = TRUE, packages = packages)
      } else {
        reticulate::virtualenv_create(envname, requirements = req_file, quiet = TRUE)
      }

      # Activate virtual environment
      reticulate::use_virtualenv(envname, required = TRUE)
    } else {
      message("Using existing virtual environment: ", envname)

      # Activate virtual environment
      reticulate::use_virtualenv(envname, required = TRUE)
    }
    # Install additional packages if provided
    if (!is.null(packages)) {
      install_missing_packages(packages, envname)
    }
    # Initialize python
    init <- reticulate::py_available(initialize = TRUE)
  }
}
