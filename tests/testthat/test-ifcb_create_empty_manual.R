test_that("ifcb_create_empty_manual creates MAT file with correct parameters", {
  # Create a temporary virtual environment
  venv_dir <- "~/.virtualenvs/iRfcb"

  # Install a temporary virtual environment
  if (reticulate::virtualenv_exists(venv_dir)) {
    reticulate::use_virtualenv(venv_dir, required = TRUE)
  } else {
    reticulate::virtualenv_create(venv_dir, requirements = system.file("python", "requirements.txt", package = "iRfcb"))
    reticulate::use_virtualenv(venv_dir, required = TRUE)
  }

  output_file <- tempfile()

  # Call the function being tested
  ifcb_create_empty_manual(
    roi_length = 100,
    class2use = c("unclassified", "Aphanizomenon_spp_filament"),
    output_file = output_file,
    unclassified_id = 1
  )

  classlist <- ifcb_get_mat_variable(output_file,
                                    "classlist")

  expect_equal(nrow(classlist), 100)

  unlink(output_file)
})
