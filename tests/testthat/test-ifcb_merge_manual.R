test_that("ifcb_merge_manual correctly updates the .mat classlist files", {
  # Define the path to the test data zip file
  zip_path <- test_path("test_data/test_data.zip")

  # Define the temporary directory for unzipping
  temp_dir <- tempdir()

  # Unzip the test data
  unzip(zip_path, exdir = temp_dir)

  # Define paths to the unzipped folders
  manual_folder <- file.path(temp_dir, "test_data/manual")
  manual_folder_additions <- file.path(temp_dir, "test_data/manual_additions")
  manual_folder_merged <- file.path(temp_dir, "test_data/manual_merged")
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

  manual_files_to <- file.path(manual_folder_additions,gsub("D2022", "D2023", basename(manual_files)))

  if (!dir.exists(manual_folder_additions)) {
    dir.create(manual_folder_additions, recursive = TRUE)
  }

  copy <- file.copy(manual_files, manual_files_to)

  ifcb_replace_mat_values(manual_folder_additions,
                          manual_folder_additions,
                          5,
                          128)

  if (!dir.exists(manual_folder_merged)) {
    dir.create(manual_folder_merged, recursive = TRUE)
  }

  ifcb_merge_manual(class2use_file,
                    class2use_file_new,
                    manual_folder,
                    manual_folder_additions,
                    manual_folder_merged)

  files_base <- list.files(manual_folder, pattern = "\\.mat$", full.names = TRUE)
  files_additions <- list.files(manual_folder_additions, pattern = "\\.mat$", full.names = TRUE)
  files_merged <- list.files(manual_folder_merged, pattern = "\\.mat$", full.names = TRUE)

  expect_equal(length(files_base) + length(files_additions), length(files_merged))

  classes_base <- as.character(ifcb_get_mat_variable(files_base[1], "class2use.manual"))
  classes_merged <- as.character(ifcb_get_mat_variable(files_merged[1], "class2use.manual"))

  expect_gt(length(classes_merged), length(classes_base))

  unlink(temp_dir, recursive = TRUE)
})
