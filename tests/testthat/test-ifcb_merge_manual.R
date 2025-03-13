test_that("ifcb_merge_manual correctly updates the .mat classlist files", {
  # Skip if Python is not available
  skip_if_no_scipy()
  skip_on_cran()

  # Define the path to the test data zip file
  zip_path <- test_path("test_data/test_data.zip")

  # Define the temporary directory for unzipping
  temp_dir <- file.path(tempdir(), "ifcb_merge_manual")

  # Unzip the test data to the temporary directory
  unzip(zip_path, exdir = temp_dir)

  # Define paths to the unzipped test data folders
  manual_folder <- file.path(temp_dir, "test_data/manual")
  manual_folder_additions <- file.path(temp_dir, "test_data/manual_additions")
  manual_folder_merged <- file.path(temp_dir, "test_data/manual_merged")
  class2use_file <- file.path(temp_dir, "test_data/config/class2use.mat")
  class2use_file_new <- file.path(temp_dir, "test_data/config/class2use_new.mat")
  class2use_file_merged <- file.path(temp_dir, "test_data/config/merged/class2use_merge.mat")

  # Load existing classes from the class2use.mat file and add a new class
  class2use <- as.character(ifcb_get_mat_variable(class2use_file))
  class2use_addition <- "New_class"

  # Insert the new class at position 127, shifting other elements forward
  class2use <- append(class2use, values = class2use_addition, after = 127 - 1)

  # Create a new class2use file with the updated classes
  ifcb_create_class2use(class2use, class2use_file_new)

  # List all .mat files in the manual folder and prepare paths for the additions folder
  manual_files <- list.files(manual_folder, pattern = "\\.mat$", full.names = TRUE)
  manual_files_to <- file.path(manual_folder_additions, gsub("D2022", "D2023", basename(manual_files)))

  # Create the manual additions folder if it doesn't exist
  if (!dir.exists(manual_folder_additions)) {
    dir.create(manual_folder_additions, recursive = TRUE)
  }

  # Copy manual .mat files to the additions folder and modify certain values
  copy <- file.copy(manual_files, manual_files_to)
  ifcb_replace_mat_values(manual_folder_additions, manual_folder_additions, 5, 128)

  # Merge the manual classification data from base and additions folders into the merged folder
  ifcb_merge_manual(class2use_file, class2use_file_new, class2use_file_merged,
                    manual_folder, manual_folder_additions,
                    manual_folder_merged, skip_class = "None")

  # Verify that the merged folder contains the correct number of files
  files_base <- list.files(manual_folder, pattern = "\\.mat$", full.names = TRUE)
  files_additions <- list.files(manual_folder_additions, pattern = "\\.mat$", full.names = TRUE)
  files_merged <- list.files(manual_folder_merged, pattern = "\\.mat$", full.names = TRUE)
  expect_equal(length(files_base) + length(files_additions), length(files_merged))

  # Ensure the merged files contain more classes than the base files
  classes_base <- as.character(ifcb_get_mat_variable(files_base[1], "class2use_manual"))
  classes_merged <- as.character(ifcb_get_mat_variable(files_merged[1], "class2use_manual"))
  expect_gt(length(classes_merged), length(classes_base))

  # Clean up the temporary directory after the test
  unlink(temp_dir, recursive = TRUE)
})

test_that("ifcb_merge_manual throws the correct error messages", {
  # Skip if Python is not available
  skip_if_no_scipy()
  skip_on_cran()

  # Define the path to the test data zip file
  zip_path <- test_path("test_data/test_data.zip")

  # Define the temporary directory for unzipping
  temp_dir <- file.path(tempdir(), "ifcb_merge_manual")

  # Unzip the test data to the temporary directory
  unzip(zip_path, exdir = temp_dir)

  # Define paths to the unzipped test data folders
  manual_folder <- file.path(temp_dir, "test_data/manual")
  manual_folder_additions <- file.path(temp_dir, "test_data/manual_additions")
  manual_folder_merged <- file.path(temp_dir, "test_data/manual_merged")
  class2use_file <- file.path(temp_dir, "test_data/config/class2use.mat")
  class2use_file_new <- file.path(temp_dir, "test_data/config/class2use_new.mat")
  no_class2use_file <- file.path(temp_dir, "not_a_path")
  no_base_folder <- file.path(temp_dir, "not_a_path")
  empty_folder <- file.path(temp_dir, "test_data/empty_folder")

  # Load existing classes from the class2use.mat file and add a new class
  class2use <- as.character(ifcb_get_mat_variable(class2use_file))
  class2use_addition <- "New_class"
  class2use <- c(class2use_addition, class2use)

  # Create a new class2use file with the updated classes
  ifcb_create_class2use(class2use, class2use_file_new)

  # List all .mat files in the manual folder and prepare paths for the additions folder
  manual_files <- list.files(manual_folder, pattern = "\\.mat$", full.names = TRUE)
  manual_files_to <- file.path(manual_folder_additions, gsub("D2022", "D2023", basename(manual_files)))

  # Create necessary directories if they do not exist
  if (!dir.exists(manual_folder_additions)) {
    dir.create(manual_folder_additions, recursive = TRUE)
  }
  if (!dir.exists(empty_folder)) {
    dir.create(empty_folder, recursive = TRUE)
  }

  # Copy manual .mat files to the additions folder
  copy <- file.copy(manual_files, manual_files_to)

  # Create the merged folder if it doesn't exist
  if (!dir.exists(manual_folder_merged)) {
    dir.create(manual_folder_merged, recursive = TRUE)
  }

  # Check that errors are thrown when expected (invalid paths or empty folders)
  expect_error(ifcb_merge_manual(no_class2use_file, class2use_file_new, NULL, manual_folder, manual_folder_additions, manual_folder_merged, quiet = TRUE),
               "Base or additions class2use file does not exist")

  expect_error(ifcb_merge_manual(class2use_file, class2use_file_new, NULL, no_base_folder, manual_folder_additions, manual_folder_merged, quiet = TRUE),
               "Base or additions manual folder does not exist")

  expect_error(ifcb_merge_manual(class2use_file, class2use_file_new, NULL, empty_folder, manual_folder_additions, manual_folder_merged, quiet = TRUE),
               "No .mat files found in manual_folder_base")

  expect_error(ifcb_merge_manual(class2use_file, class2use_file_new, NULL, manual_folder, empty_folder, manual_folder_merged, quiet = TRUE),
               "No .mat files found in manual_folder_additions")

  # Clean up the temporary directory after the test
  unlink(temp_dir, recursive = TRUE)
})
