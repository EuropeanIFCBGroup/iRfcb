test_that("ifcb_adjust_classes correctly updates the .mat classlist files", {

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

test_that("ifcb_adjust_classes fail gracefully if files or folders do not exist", {
  # Expect error when file does not exist
  expect_error(ifcb_adjust_classes("not_a_file", tempdir()),
               "does not exist")

  tmp_file <- tempfile(fileext = ".mat")  # create a temp file path
  file.create(tmp_file)

  # Expect error when folder does not exist
  expect_error(ifcb_adjust_classes(tmp_file, "not_a_dir"),
               "does not exist")

  # Clean up
  unlink(tmp_file)
})

test_that("ifcb_adjust_classes refuses a config file without a class2use variable", {
  temp_dir <- file.path(tempdir(), "adjust_no_class2use")
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  manual_folder <- file.path(temp_dir, "manual")
  dir.create(manual_folder, showWarnings = FALSE, recursive = TRUE)

  # A manual file that must survive the failed call untouched. Its
  # class2use_manual would previously have been overwritten with an empty
  # cell array, because `$class2use` partial-matched to NULL.
  manual_file <- file.path(manual_folder, "D20220101T000000_IFCB001.mat")
  write_mat_v5(manual_file, list(
    classlist = mat_var_double(cbind(1:2, c(1, 2), c(NaN, NaN))),
    class2use_manual = mat_var_cell(matrix(c("classA", "classB"), nrow = 1))
  ))
  before <- readBin(manual_file, "raw", file.size(manual_file))

  # A config file holding variables under other names, e.g. a manual file
  # passed by mistake.
  bad_config <- file.path(temp_dir, "not_a_config.mat")
  write_mat_v5(bad_config, list(
    class2use_manual = mat_var_cell(matrix("classA"))
  ))

  expect_error(
    ifcb_adjust_classes(bad_config, manual_folder),
    "class2use"
  )
  expect_identical(readBin(manual_file, "raw", file.size(manual_file)), before)
})

test_that("a reader refusal is reported with its own message, not 'empty or corrupted'", {
  temp_dir <- file.path(tempdir(), "adjust_refusal_msg")
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  manual_folder <- file.path(temp_dir, "manual")
  dir.create(manual_folder, showWarnings = FALSE, recursive = TRUE)

  config <- file.path(temp_dir, "class2use.mat")
  write_mat_v5(config, list(class2use = mat_var_cell(matrix(c("a", "b"), nrow = 1))))

  # A manual file the reader deliberately refuses: stray trailing bytes.
  bad <- file.path(manual_folder, "D20220101T000000_IFCB001.mat")
  write_mat_v5(bad, list(classlist = mat_var_double(matrix(1))))
  writeBin(c(readBin(bad, "raw", file.size(bad)), as.raw(c(1, 2, 3))), bad)

  # The refusal reason must reach the user; it used to be relabelled
  # "empty or corrupted".
  expect_warning(ifcb_adjust_classes(config, manual_folder), "stray byte")
})
