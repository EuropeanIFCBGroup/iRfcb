.iRfcbEnv <- new.env(parent = emptyenv())
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
  reqs <- scan(req_file, what = character(), quiet = TRUE)
  reticulate::py_require(reqs)

  .iRfcbEnv$venv <- NULL

  if (Sys.getenv("USE_IRFCB_PYTHON") == "TRUE") {
    py_exec <- if (.Platform$OS.type == "windows") "Scripts/python.exe" else "bin/python"

    # Optional: user-specified venv (named virtualenv OR full path to a venv dir)
    requested <- Sys.getenv("IRFCB_PYTHON_VENV", unset = "")

    if (nzchar(requested)) {
      python_path <- NULL

      if (dir.exists(requested)) {
        # Full path to a venv directory
        candidate <- file.path(requested, py_exec)
        if (file.exists(candidate)) python_path <- candidate
      } else if (reticulate::virtualenv_exists(requested)) {
        # Named virtualenv under reticulate's root
        python_path <- reticulate::virtualenv_python(requested)
      }

      if (!is.null(python_path)) {
        .iRfcbEnv$venv <- requested
        Sys.setenv(RETICULATE_PYTHON = python_path)
        reticulate::py_available(initialize = TRUE)
      }
      # If not resolvable, .iRfcbEnv$venv stays NULL (no fallback to auto-discovery)

    } else {
      # No explicit venv requested -> auto-discover an "iRfcb" venv (original behaviour)
      venv_list <- reticulate::virtualenv_list()
      iRfcb_venvs <- venv_list[grepl("iRfcb", venv_list)]
      for (venv in iRfcb_venvs) {
        if (reticulate::virtualenv_exists(venv)) {
          .iRfcbEnv$venv <- venv
          Sys.setenv(RETICULATE_PYTHON = file.path(reticulate::virtualenv_root(), venv, py_exec))
          reticulate::py_available(initialize = TRUE)
          break
        }
      }
    }
  }
}

.onAttach <- function(libname, pkgname) {
  if (!is.null(.iRfcbEnv$venv)) {
    packageStartupMessage("Using existing Python virtual environment: ", .iRfcbEnv$venv)
  }
}
