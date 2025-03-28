test_that("ifcb_adjust_classes correctly updates the .mat classlist files", {
  # Skip if scipy is not available
  skip_if_no_scipy()

  # Define the path to the test data zip file
  zip_path <- test_path("test_data/test_data.zip") # Path to the test data zip file containing .mat files and config

  # Define the temporary directory for unzipping
  temp_dir <- file.path(tempdir(), "ifcb_adjust_classes") # Create a temporary directory to extract the zip contents

  # Unzip the test data into the temporary directory
  unzip(zip_path, exdir = temp_dir) # Extract the test data

  # Define paths to the unzipped folders and files
  manual_folder <- file.path(temp_dir, "test_data/manual") # Folder containing manual .mat files
  class2use_file <- file.path(temp_dir, "test_data/config/class2use.mat") # Original class2use file
  class2use_file_new <- file.path(temp_dir, "test_data/config/class2use_new.mat") # Updated class2use file

  # Read the existing class names from the class2use file
  class2use <- as.character(ifcb_get_mat_variable(class2use_file)) # Extract class list from original file

  # Define a new class to add
  class2use_addition <- "New_class" # Add a new class to the list

  # Append the new class to the existing class list
  class2use <- c(class2use, class2use_addition) # Combine old and new class

  # Create a new class2use file with the updated class list
  ifcb_create_class2use(class2use, class2use_file_new) # Save the updated class2use list

  # Get a list of manual .mat files from the manual folder
  manual_files <- list.files(manual_folder, pattern = "\\.mat$", full.names = TRUE) # List all .mat files in the manual folder

  # Extract the class list from the first .mat file (before update)
  class_list_old <- as.character(ifcb_get_mat_variable(manual_files[1], "class2use_manual")) # Old class list

  # Call the function to adjust the classes in the manual folder based on the updated class2use file
  ifcb_adjust_classes(class2use_file_new, manual_folder) # Adjust the classes in .mat files

  # Extract the updated class list from the first .mat file (after update)
  class_list_updated <- as.character(ifcb_get_mat_variable(manual_files[1], "class2use_manual")) # New class list

  # Assert that the updated class list contains more classes than the old list
  expect_gt(length(class_list_updated), length(class_list_old)) # Check that the updated list has more classes

  # Clean up the temporary directory
  unlink(temp_dir, recursive = TRUE) # Delete the temporary directory and its contents
})
