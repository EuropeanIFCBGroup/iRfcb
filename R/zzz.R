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

  # Check required packages
  reqs <- scan(req_file, what = character(), quiet = TRUE)

  # List required packages
  reticulate::py_require(reqs)

  # You can store info in a package env to retrieve later if needed
  .iRfcbEnv$venv <- NULL

  # Only set up environment, no messages
  if (Sys.getenv("USE_IRFCB_PYTHON") == "TRUE") {
    venv_list <- reticulate::virtualenv_list()
    iRfcb_venvs <- venv_list[grepl("iRfcb", venv_list)]

    found <- FALSE
    for (venv in iRfcb_venvs) {
      if (reticulate::virtualenv_exists(venv)) {
        .iRfcbEnv$venv <- venv
        py_exec <- if (.Platform$OS.type == "windows") "Scripts/python.exe" else "bin/python"
        Sys.setenv(RETICULATE_PYTHON = file.path(reticulate::virtualenv_root(), venv, py_exec))
        reticulate::py_available(initialize = TRUE)
        found <- TRUE
        break
      }
    }

    if (!found) {
      .iRfcbEnv$venv <- NULL
    }
  }
}

.onAttach <- function(libname, pkgname) {
  if (!is.null(.iRfcbEnv$venv)) {
    packageStartupMessage("Using existing Python virtual environment: ", .iRfcbEnv$venv)
  }
}

.ifcb_checksums <- list(
  "48158716" = "3f393747663f9586212e9cb6bfa090e3", # smhi_ifcb_iRfcb_matlab_files.zip v3
  "50176191" = "943920edc9f7a2b4e1146daec8a6fb35", # smhi_ifcb_baltic_annotated_images.zip
  "50176674" = "16e94675c5f080c5c4e50290a18c248f", # smhi_ifcb_baltic_matlab_files.zip
  "50174991" = "4240347b217fee7710294f8609715dbc", # smhi_ifcb_skagerrak-kattegat_annotated_images.zip
  "50176071" = "45a798bc8b4aba3a4ea5a8ae9b24d82f", # smhi_ifcb_skagerrak-kattegat_matlab_files.zip
  "50176155" = "d625d2a31b3d926fe4cafc62651e3293", # smhi_ifcb_tangesund_annotated_images.zip
  "50177859" = "ebab38243c0cd03d64b33094e6b0406f", # smhi_ifcb_tangesund_matlab_files.zip
  "50174988" = "632af1d33f957717b0209aa096316e92"  # smhi_ifcb_iRfcb_matlab_files.zip v4
)
