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
#'   with its dependencies (a raw-data reader, `phasepack`, `scikit-image`,
#'   `scikit-learn`).
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
#'   The choice of reference determines which raw-data reader is installed:
#'   `ifcb-features` v1.1.0 and later depend on `ifcbkit`, while v1.0.0 and
#'   earlier depend on `pyifcb`. `iRfcb` supports both, so either reference
#'   works and the two readers may coexist in one environment. The feature code
#'   itself is unchanged between these releases, so the choice does not in
#'   itself affect how a region of interest is measured, and for the D-style
#'   bins produced by current instruments the two readers agree. They differ for
#'   older I-style bins, which `ifcbkit` stitches and `pyifcb` does not, and on
#'   ROIs with a zero height; see [ifcb_extract_features()], whose `backend`
#'   argument pins a reader when both are installed.
#'
#'   The reference does, however, decide which `numpy` version is installed, and
#'   that changes how a degenerate (collinear) blob is measured. Pinning
#'   `"v1.0.0"` pulls in `pyifcb`, whose dependencies resolve `numpy` to below
#'   2.3, where `numpy.linalg.eig()` returns real eigenvalues and such a blob is
#'   reported as `NaN` in the `Eccentricity`, `MajorAxisLength` and
#'   `MinorAxisLength` columns. The `ifcbkit`-based releases leave `numpy`
#'   unconstrained, so a current install measures the same blob as `0`, matching
#'   upstream `ifcb-features`. Pin `"v1.0.0"`, or `numpy < 2.3`, to reproduce a
#'   run made before `iRfcb` 0.10.0; see [ifcb_extract_features()].
#'
#'   Note that installing v1.0.0 or earlier pulls in `pyifcb`, which requires
#'   binary wheels for `h5py` (available for Python 3.10-3.13). Installation
#'   fails on Python versions without such a wheel. The `ifcbkit`-based
#'   releases have no such constraint and require only Python >= 3.10.
#'
#'   Whichever reference is used, `scikit-image` is constrained to `< 0.28`,
#'   because `ifcb-features` calls morphology functions that are scheduled for
#'   removal in that release.
#'
#' @return No return value. This function is called for its side effect of configuring the Python environment.
#'
#' @details
#' This function requires Python to be available on the system. It uses the `reticulate` package to
#' manage Python environments and packages.
#'
#' The `USE_IRFCB_PYTHON` environment variable can be set to `"TRUE"` to automatically
#' activate an installed Python venv when the `iRfcb` package is loaded. By default this
#' activates a venv named `iRfcb` found in `reticulate::virtualenv_root()` (available via
#' `reticulate::virtualenv_list()`; see examples). To activate a specific environment
#' instead, also set the `IRFCB_PYTHON_VENV` variable to either the name of a venv under
#' `reticulate::virtualenv_root()` or a full path to a venv directory. Both variables can
#' be set in your `.Renviron` file to enable automatic setup across sessions.
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
      packages <- unique(c(packages, resolve_ifcb_features_url(features_ref),
                           ifcb_features_constraints()))
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
        packages <- unique(c(packages, resolve_ifcb_features_url(features_ref),
                             ifcb_features_constraints()))
      }
    }

    # Install additional packages if provided
    if (!is.null(packages)) {
      tryCatch(
        install_missing_packages(packages, envname),
        error = function(e) {
          msg <- conditionMessage(e)
          if (features && grepl("Cython|pyx|compil|build.*error|error.*build",
                                msg, ignore.case = TRUE)) {
            cli_abort(c(
              "Failed to install {.pkg ifcb-features} dependencies from source.",
              "x" = msg,
              "i" = "A dependency (likely {.pkg h5py}, required by {.pkg pyifcb}) has no binary wheel for your Python version.",
              "i" = "{.pkg pyifcb} is only used by {.pkg ifcb-features} v1.0.0 and earlier; newer releases use {.pkg ifcbkit}, which has no such constraint.",
              "i" = "Install a newer release with {.code ifcb_py_install(features = TRUE)}, or a compatible Python with {.code reticulate::install_python(\"3.12:latest\")}."
            ))
          } else {
            cli_abort(c("Failed to install Python packages.", "x" = msg))
          }
        }
      )
    }
    # Initialize python
    init <- reticulate::py_available(initialize = TRUE)
  }
}
