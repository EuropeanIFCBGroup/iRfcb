test_that("ifcb_annotate_samples correctly updates the .mat classlist files", {
  # Skip if scipy is not available
  skip_if_no_scipy()

  # Define the path to the test data zip file
  zip_path <- test_path("test_data/test_data.zip") # Path to the test data zip file containing .mat files and config

  # Define the temporary directory for unzipping
  temp_dir <- file.path(tempdir(), "ifcb_annotate_samples") # Create a temporary directory to extract the zip contents

  # Unzip the test data into the temporary directory
  unzip(zip_path, exdir = temp_dir) # Extract the test data

  # Define paths to the unzipped folders and files
  png_folder <- file.path(temp_dir, "test_data/png2")
  adc_folder <- file.path(temp_dir, "test_data/data")
  output_folder <- file.path(temp_dir, "test_data/output")
  class2use_file <- file.path(temp_dir, "test_data/config/class2use.mat")
  sample_names <- "D20220522T003051_IFCB134"

  # Call the function
  ifcb_annotate_samples(png_folder = png_folder,
                        adc_folder = adc_folder,
                        class2use_file = class2use_file,
                        output_folder = output_folder,
                        sample_names = NULL)

  # Define path to the newly created file
  new_file <- file.path(output_folder, paste0(sample_names, ".mat"))

  # Make sure file exists
  expect_true(file.exists(new_file))

  # Read the file
  classlist <- ifcb_get_mat_variable(new_file, "classlist")

  expected_classlist <- c(NaN, 1, 5) # NaN for empty trigger, 1 for unclassified and 5 for Mesodinium_rubrum

  # Make sure data is correct
  expect_equal(nrow(classlist), 3)
  expect_equal(ncol(classlist), 3)
  expect_equal(classlist[,2], expected_classlist)

  # Clean up the temporary directory
  unlink(temp_dir, recursive = TRUE) # Delete the temporary directory and its contents
})

test_that("ifcb_annotate_samples correctly updates the .mat classlist files if classes are unmatches", {
  # Skip if scipy is not available
  skip_if_no_scipy()

  # Define the path to the test data zip file
  zip_path <- test_path("test_data/test_data.zip") # Path to the test data zip file containing .mat files and config

  # Define the temporary directory for unzipping
  temp_dir <- file.path(tempdir(), "ifcb_annotate_samples") # Create a temporary directory to extract the zip contents

  # Unzip the test data into the temporary directory
  unzip(zip_path, exdir = temp_dir) # Extract the test data

  # Define paths to the unzipped folders and files
  png_folder <- file.path(temp_dir, "test_data/png2")
  adc_folder <- file.path(temp_dir, "test_data/data")
  output_folder <- file.path(temp_dir, "test_data/output")
  class2use_file <- file.path(temp_dir, "test_data/config/class2use.mat")
  sample_names <- "D20220522T003051_IFCB134"
  class2use_file_new <- file.path(temp_dir, "test_data/config/class2use_new.mat") # Updated class2use file

  # Read the existing class names from the class2use file
  class2use <- as.character(ifcb_get_mat_variable(class2use_file)) # Extract class list from original file

  # Define a new class to add
  class2use[5] <- "Mesodinium"

  # Create a new class2use file with the updated class list
  ifcb_create_class2use(class2use, class2use_file_new) # Save the updated class2use list

  # Call the function
  expect_warning(ifcb_annotate_samples(sample_names = sample_names,
                                       png_folder = png_folder,
                                       adc_folder = adc_folder,
                                       output_folder = output_folder,
                                       class2use_file = class2use_file_new),
                 "Some classes could not be matched to class_id values")

  # Define path to the newly created file
  new_file <- file.path(output_folder, paste0(sample_names, ".mat"))

  # Make sure file exists
  expect_true(file.exists(new_file))

  # Read the file
  classlist <- ifcb_get_mat_variable(new_file, "classlist")

  expected_classlist <- c(NaN,1,1) # NaN for empty trigger, 1 for unclassified and 5 for Mesodinium_rubrum

  # Make sure data is correct
  expect_equal(nrow(classlist), 3)
  expect_equal(ncol(classlist), 3)
  expect_equal(classlist[,2], expected_classlist)

  # Clean up the temporary directory
  unlink(temp_dir, recursive = TRUE)
})

test_that("ifcb_annotate_samples handles missing directories and files gracefully", {
  # Skip if scipy is not available
  skip_if_no_scipy()

  # Define the path to the test data zip file
  zip_path <- test_path("test_data/test_data.zip") # Path to the test data zip file containing .mat files and config

  # Define the temporary directory for unzipping
  temp_dir <- file.path(tempdir(), "ifcb_annotate_samples") # Create a temporary directory to extract the zip contents

  # Unzip the test data into the temporary directory
  unzip(zip_path, exdir = temp_dir) # Extract the test data

  # Define paths to the unzipped folders and files
  png_folder <- file.path(temp_dir, "test_data/png2")
  adc_folder <- file.path(temp_dir, "test_data/data")
  output_folder <- file.path(temp_dir, "test_data/output")
  class2use_file <- file.path(temp_dir, "test_data/config/class2use.mat")
  sample_names <- "D20220522T003051_IFCB134"

  # Exoect errors
  expect_error(ifcb_annotate_samples(sample_names = sample_names,
                                     png_folder = "not_a_dir",
                                     adc_folder = adc_folder,
                                     output_folder = output_folder,
                                     class2use_file = class2use_file),
               "directory does not exist")

  expect_error(ifcb_annotate_samples(sample_names = sample_names,
                                     png_folder = png_folder,
                                     adc_folder = "not_a_dir",
                                     output_folder = output_folder,
                                     class2use_file = class2use_file),
               "directory does not exist")

  expect_error(ifcb_annotate_samples(sample_names = sample_names,
                                     png_folder = png_folder,
                                     adc_folder = adc_folder,
                                     output_folder = output_folder,
                                     class2use_file = "not_a_file"),
               "class2use file does not exist")

  expect_error(ifcb_annotate_samples(sample_names = sample_names,
                                     png_folder = adc_folder,
                                     adc_folder = adc_folder,
                                     output_folder = output_folder,
                                     class2use_file = class2use_file),
               "No PNG images found in")

  expect_error(ifcb_annotate_samples(sample_names = sample_names,
                                     png_folder = png_folder,
                                     adc_folder = png_folder,
                                     output_folder = output_folder,
                                     class2use_file = class2use_file),
               "No ADC files found in")

  copy <- file.copy(file.path(adc_folder, paste0(sample_names, ".adc")),
                    file.path(adc_folder, paste0(sample_names, "_copy.adc")))

  expect_warning(ifcb_annotate_samples(sample_names = sample_names,
                                       png_folder = png_folder,
                                       adc_folder = adc_folder,
                                       output_folder = output_folder,
                                       class2use_file = class2use_file),
                 "Multiple ADC files found for sample")

  # Define path to the newly created file
  new_file <- file.path(output_folder, paste0(sample_names, ".mat"))

  # Make sure file exists
  expect_true(file.exists(new_file))

  # Clean up the temporary directory
  unlink(temp_dir, recursive = TRUE)
})
