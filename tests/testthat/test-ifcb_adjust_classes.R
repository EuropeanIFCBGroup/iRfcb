test_that("ifcb_adjust_classes correctly updates the .mat classlist files", {
  # Define the path to the test data zip file
  zip_path <- test_path("test_data/test_data.zip")

  # Define the temporary directory for unzipping
  temp_dir <- tempdir()

  # Unzip the test data
  unzip(zip_path, exdir = temp_dir)

  # Define paths to the unzipped folders
  manual_folder <- file.path(temp_dir, "test_data/manual")
  class2use_file <- file.path(temp_dir, "test_data/config/class2use.mat")
  class2use_file_new <- file.path(temp_dir, "test_data/config/class2use_new.mat")

  class2use <- as.character(ifcb_get_mat_variable(class2use_file))
  class2use_addition <- "New_class"

  class2use <- c(class2use, class2use_addition)

  # Create a temporary virtual environment
  venv_dir <- "~/.virtualenvs/iRfcb"

  # Install a temporary virtual environment
  if (reticulate::virtualenv_exists(venv_dir)) {
    reticulate::use_virtualenv(venv_dir, required = TRUE)
  } else {
    reticulate::virtualenv_create(venv_dir, requirements = system.file("python", "requirements.txt", package = "iRfcb"))
    reticulate::use_virtualenv(venv_dir, required = TRUE)
  }

  ifcb_create_class2use(class2use, class2use_file_new)

  manual_files <- list.files(manual_folder, pattern = "\\.mat$", full.names = TRUE)

  class_list_old <- as.character(ifcb_get_mat_variable(manual_files[1], "class2use.manual"))

  ifcb_adjust_classes(class2use_file_new,
                      manual_folder)

  class_list_updated <- as.character(ifcb_get_mat_variable(manual_files[1], "class2use.manual"))

  expect_gt(length(class_list_updated), length(class_list_old))

  unlink(temp_dir, recursive = TRUE)
})
