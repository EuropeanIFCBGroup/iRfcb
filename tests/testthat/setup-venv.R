library(reticulate)

# Check if we are on CRAN
not_cran <- identical(Sys.getenv("NOT_CRAN"), "true")

if (not_cran) {
  # Define the virtual environment path
  venv_dir <- file.path(tempdir(), "test-venv")

  # Use an isolated virtual environment for tests
  if (!reticulate::virtualenv_exists(venv_dir)) {
    message("Creating temporary Python virtual environment for tests...")
    reticulate::virtualenv_create(venv_dir, requirements = system.file("python", "requirements.txt", package = "iRfcb"))
  }

  # Activate the virtual environment
  reticulate::use_virtualenv(venv_dir, required = TRUE)
}
