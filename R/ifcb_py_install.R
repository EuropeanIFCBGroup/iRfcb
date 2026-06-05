#' Install iRfcb Python Environment
#'
#' This function sets up the Python environment for `iRfcb`. By default, it creates and activates a Python virtual environment (`venv`) named "iRfcb" and installs the required Python packages from the "requirements.txt" file.
#' Alternatively, users can opt to use the system Python instead of creating a virtual environment by setting `use_venv = FALSE` (not recommended).
#'
#' @param envname A character string specifying the name of the virtual environment to create. Default is "~/.virtualenvs/iRfcb".
#' @param use_venv Logical. If `TRUE` (default), a virtual environment is created. If `FALSE`, the system Python is used instead, and missing packages are installed globally for the user.
#' @param packages A character vector of additional Python packages to install. If NULL (default), only the packages from "requirements.txt" are installed.
#' @param features Logical. If `TRUE`, additionally installs the WHOI `ifcb-features`
#'   package (\url{https://github.com/WHOIGit/ifcb-features}) from GitHub, together
#'   with its dependencies (`pyifcb`, `phasepack`, `scikit-image`, `scikit-learn`).
#'   This is required by `ifcb_extract_features()`. Default is `FALSE` to keep the
#'   default environment lightweight. When installing into an existing virtual
#'   environment, the (slow) install is skipped if `ifcb-features` already imports
#'   successfully, unless `features_ref` is given.
#' @param features_ref A character string specifying which git reference (release
#'   tag, branch, or commit) of `ifcb-features` to install when `features = TRUE`.
#'   If `NULL` (default), the latest published GitHub release is installed, which
#'   is more stable than the actively developed default branch. Use
#'   `features_ref = "main"` to install the latest development commit, or a tag
#'   such as `"v1.0.0"` to pin a specific version.
#'
#' @return No return value. This function is called for its side effect of configuring the Python environment.
#'
#' @details
#' This function requires Python to be available on the system. It uses the `reticulate` package to
#' manage Python environments and packages.
#'
#' The `USE_IRFCB_PYTHON` environment variable can be set to automatically activate an
#' installed Python venv named `iRfcb` when the `iRfcb` package is loaded.
#' Ensure that the `iRfcb` venv is installed in `reticulate::virtualenv_root()`
#' and available via `reticulate::virtualenv_list()` (see examples). You can set
#' `USE_IRFCB_PYTHON` to `"TRUE"` in your `.Renviron` file to enable automatic setup.
#' For more details, see the package README
#' at \url{https://europeanifcbgroup.github.io/iRfcb/#python-dependency}.
#'
#' @examples
#' \dontrun{
#' # Define the name of the virtual environment in your virtual_root directory
#' envpath <- file.path(reticulate::virtualenv_root(), "iRfcb")
#'
#' # Install the iRfcb Python venv in your virtual_root directory
#' ifcb_py_install(envname = envpath)
#'
#' # Install the iRfcb Python environment with additional packages
#' ifcb_py_install(envname = envpath, packages = c("numpy", "plotly"))
#'
#' # Install the iRfcb Python venv including the WHOI ifcb-features package
#' # (latest release by default)
#' ifcb_py_install(envname = envpath, features = TRUE)
#'
#' # Install a specific ifcb-features version, or the development branch
#' ifcb_py_install(envname = envpath, features = TRUE, features_ref = "v1.0.0")
#' ifcb_py_install(envname = envpath, features = TRUE, features_ref = "main")
#'
#' # Use system Python instead of a virtual environment
#' ifcb_py_install(envname = envpath, use_venv = FALSE)
#' }
#' @export
ifcb_py_install <- function(envname = "~/.virtualenvs/iRfcb", use_venv = TRUE, packages = NULL, features = FALSE, features_ref = NULL) {
  # Get the path to the requirements file
  req_file <- system.file("python", "requirements.txt", package = "iRfcb")

  if (!file.exists(req_file)) {
    cli_abort("Requirements file not found: {.file {req_file}}")
  }

  # If use_venv is FALSE, use system Python
  if (!use_venv) {
    cli_inform("Using system Python instead of a virtual environment.")

    # Dynamically discover system Python executable
    py_config <- reticulate::py_discover_config()
    python_path <- py_config$python

    if (is.null(python_path)) {
      cli_abort(c(
        "Could not find a valid Python installation.",
        "i" = "Please ensure Python is installed."
      ))
    }

    # Use the discovered Python path
    reticulate::use_python(python_path, required = TRUE)

    # Optionally include WHOI's ifcb-features package (installed from GitHub)
    if (features) {
      packages <- unique(c(packages, resolve_ifcb_features_url(features_ref)))
    }

    # Read required packages from requirements.txt
    required_packages <- scan(req_file, what = character(), quiet = TRUE)

    # Combine required packages with additional ones
    all_packages <- unique(c(required_packages, packages))

    # Declare Python Requirements
    reticulate::py_require(all_packages)

    # Initialize python
    temp <- py_available(initialize = TRUE)
  } else {
    # Otherwise, create or use the virtual environment
    if (!reticulate::virtualenv_exists(envname)) {
      cli_inform("Creating virtual environment: {.file {envname}}")
      reticulate::virtualenv_create(envname, requirements = req_file, quiet = TRUE)

      # Activate virtual environment
      reticulate::use_virtualenv(envname, required = TRUE)
    } else {
      cli_inform("Using existing virtual environment: {.file {envname}}")

      # Activate virtual environment
      reticulate::use_virtualenv(envname, required = TRUE)
    }

    # Optionally include WHOI's ifcb-features package (installed from GitHub).
    # If no specific reference is requested and the module already imports in the
    # activated environment, skip the (slow) git install. An explicit
    # `features_ref` always (re)installs, so a specific version can be forced.
    if (features) {
      if (is.null(features_ref) &&
          isTRUE(tryCatch(reticulate::py_module_available("ifcb_features"),
                          error = function(e) FALSE))) {
        cli_inform(c(
          "{.pkg ifcb-features} is already installed; skipping installation.",
          "i" = "Set {.arg features_ref} to (re)install a specific version."
        ))
      } else {
        packages <- unique(c(packages, resolve_ifcb_features_url(features_ref)))
      }
    }

    # Install additional packages if provided
    if (!is.null(packages)) {
      install_missing_packages(packages, envname)
    }
    # Initialize python
    init <- reticulate::py_available(initialize = TRUE)
  }
}
