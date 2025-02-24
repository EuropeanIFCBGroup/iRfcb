library(reticulate)

# Create a temporary directory for the virtual environment
venv_dir <- file.path(tempdir(), "test-venv")

if (!reticulate::virtualenv_exists(venv_dir)) {
  message("Creating temporary Python virtual environment for tests...")
  reticulate::virtualenv_create(venv_dir)
  reticulate::virtualenv_install(venv_dir, requirements = system.file("python", "requirements.txt", package = "iRfcb"))
}

reticulate::use_virtualenv(venv_dir, required = TRUE) # Use the newly created virtual environment
