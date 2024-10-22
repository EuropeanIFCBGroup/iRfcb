test_that("ifcb_create_class2use creates .mat file correctly", {

  # Define test parameters
  classes <- c("unclassified", "Dinobryon_spp", "Helicostomella_spp")
  filename <- tempfile(fileext = ".mat")  # Create a temporary file for the test

  # Create a temporary virtual environment
  venv_dir <- "~/.virtualenvs/iRfcb"

  # Install a temporary virtual environment
  if (reticulate::virtualenv_exists(venv_dir)) {
    reticulate::use_virtualenv(venv_dir, required = TRUE)
  } else {
    reticulate::virtualenv_create(venv_dir, requirements = system.file("python", "requirements.txt", package = "iRfcb"))
    reticulate::use_virtualenv(venv_dir, required = TRUE)
  }

  # Call the function
  ifcb_create_class2use(classes, filename, do_compression = TRUE)

  # Check if the file was created
  expect_true(file.exists(filename))

  # Load the .mat file and check its contents
  mat_data <- ifcb_get_mat_variable(filename)

  # Verify that the "class2use" in the .mat file matches the input classes
  expect_equal(as.character(mat_data), classes)

  # Clean up
  unlink(filename)
})
