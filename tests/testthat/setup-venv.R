library(reticulate)

# Define virtual environment path
venv_dir <- file.path(tempdir(), "test-venv")

# Check if running on CRAN
if (identical(Sys.getenv("NOT_CRAN"), "true")) {

  # Create virtual environment if it doesn't exist
  if (!reticulate::virtualenv_exists(venv_dir)) {
    message("Creating temporary Python virtual environment for tests...")
    reticulate::virtualenv_create(venv_dir)
    reticulate::virtualenv_install(venv_dir,
                                   packages = c("scipy", "matplotlib", "pandas"))
  }

  reticulate::use_virtualenv(venv_dir, required = TRUE) # Use the virtual environment
  Sys.setenv(SKIP_PYTHON_TESTS = "false") # Allow Python-dependent tests

} else {
  message("Skipping virtual environment setup on CRAN.")

  # Try to use system Python
  py_exe <- Sys.which("python3")
  if (!nzchar(py_exe)) {
    py_exe <- Sys.which("python")
  }

  if (nzchar(py_exe)) {
    reticulate::use_python(py_exe, required = TRUE)

    # Ensure required Python packages are installed
    required_packages <- c("scipy", "matplotlib", "pandas")
    installed_packages <- reticulate::py_list_packages()$package

    missing_packages <- setdiff(required_packages, installed_packages)
    if (length(missing_packages) > 0) {
      message("Missing Python packages: ", paste(missing_packages, collapse = ", "))
      Sys.setenv(SKIP_PYTHON_TESTS = "true") # Flag to skip Python-dependent tests
    } else {
      Sys.setenv(SKIP_PYTHON_TESTS = "false") # All packages are available, run tests
    }
  } else {
    message("No Python environment available. Python-dependent tests will be skipped.")
    Sys.setenv(SKIP_PYTHON_TESTS = "true")
  }
}
