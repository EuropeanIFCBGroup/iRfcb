library(reticulate)

if (.Platform$OS.type == "windows") {
  Sys.setenv(PIP_NO_CACHE_DIR = "1")
}

# Check if we are on CRAN
not_cran <- identical(Sys.getenv("NOT_CRAN"), "true")

if (not_cran) {
  # Define the virtual environment path
  venv_dir <- file.path(tempdir(), "test-venv")
  python_path <- Sys.which("python3")

  # Use an isolated virtual environment for tests
  if (!reticulate::virtualenv_exists(venv_dir)) {
    message("Creating temporary Python virtual environment for tests...")
    reticulate::virtualenv_create(venv_dir,
                                  python = python_path,
                                  requirements = system.file("python", "requirements.txt", package = "iRfcb"))
  }

  # Activate the virtual environment
  reticulate::use_virtualenv(venv_dir, required = TRUE)

  # Install ifcb-features so that ifcb_extract_features() tests can run.
  # ifcb_py_install() skips the install if the module already imports successfully,
  # so repeated test runs do not re-download from GitHub.
  # Note: requires Python 3.12 in CI (not 3.x/3.13) because h5py (a pyifcb
  # dependency) only has binary wheels for 3.12; source compilation fails with
  # numpy 2.x on 3.13.
  iRfcb::ifcb_py_install(envname = venv_dir, features = TRUE)
}
