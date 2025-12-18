# Define the path to the test data zip file
zip_path <- test_path("test_data/test_data.zip")

# Define the temporary directory for unzipping
temp_dir <- file.path(tempdir(), "ifcb_extract_biovolumes")

# Unzip the test data
unzip(zip_path, exdir = temp_dir)

# Define paths to the unzipped folders
feature_folder <- file.path(temp_dir, "test_data/features")
class_folder <- file.path(temp_dir, "test_data/class/class2022_v1")
manual_folder <- file.path(temp_dir, "test_data/manual")
class2use_file <- file.path(temp_dir, "test_data/config/class2use.mat")

test_that("ifcb_extract_biovolumes works correctly", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://marinespecies.org")

  # Run the function with test data
  biovolume_df <- ifcb_extract_biovolumes(feature_folder,
                                          class_folder,
                                          micron_factor = 1 / 3.4,
                                          diatom_class = "Bacillariophyceae",
                                          threshold = "opt",
                                          multiblob = FALSE)

  # Run the function using python
  biovolume_py <- ifcb_extract_biovolumes(feature_folder,
                                          class_folder,
                                          micron_factor = 1 / 3.4,
                                          diatom_class = "Bacillariophyceae",
                                          threshold = "opt",
                                          multiblob = FALSE,
                                          use_python = TRUE)

  # Run the function with diatom_include
  biovolume_diatom_include <- ifcb_extract_biovolumes(feature_folder,
                                                      class_folder,
                                                      micron_factor = 1 / 3.4,
                                                      diatom_class = "Bacillariophyceae",
                                                      diatom_include = "Mesodinium_rubrum",
                                                      threshold = "opt",
                                                      multiblob = FALSE)

  # Check that the .mat data from R and Python are identical
  expect_identical(biovolume_df$sample, biovolume_py$sample)
  expect_identical(biovolume_df$biovolume_um3, biovolume_py$biovolume_um3)
  expect_identical(biovolume_df$roi_number, biovolume_py$roi_number)

  # Sum carbon content
  sum_carbon <- sum(biovolume_df$carbon_pg)
  sum_diatom_include <- sum(biovolume_diatom_include$carbon_pg)

  # Check that carbon content is greater when M. rubrum is considered NOT diatom
  expect_gt(sum_carbon, sum_diatom_include)

  # Check that the returned object is a data frame
  expect_s3_class(biovolume_df, "data.frame")

  # Check that the data frame contains the expected columns
  expected_columns <- c("sample", "roi_number", "class", "biovolume_um3", "carbon_pg")
  expect_true(all(expected_columns %in% names(biovolume_df)))

  # Check that the data frame has non-zero rows
  expect_gt(nrow(biovolume_df), 0)

  # Check some specific values (replace with expected values based on your test data)
  # Example: Check if specific sample and roi_number exist in the output
  expect_true("D20220522T003051_IFCB134" %in% biovolume_df$sample)
  expect_true(2 %in% biovolume_df$roi_number)

  # Example: Check if biovolume_um3 and carbon_pg are calculated correctly
  # Replace the following expected values with the actual expected values from your test data
  expected_biovolume_um3 <- 5206.2003  # Example value
  expect_equal(biovolume_df$biovolume_um3[1], expected_biovolume_um3, tolerance = 1e-8)

  expected_carbon_pg <- 668.05635  # Example value
  expect_equal(biovolume_df$carbon_pg[1], expected_carbon_pg, tolerance = 1e-8)
})

test_that("ifcb_extract_biovolumes handles empty directories", {

  # Define empty directories for features and class
  empty_feature_dir <- file.path(temp_dir, "empty_features")
  empty_class_dir <- file.path(temp_dir, "empty_class")

  dir.create(empty_feature_dir)
  dir.create(empty_class_dir)

  # Run the function with empty feature directory and expect an error
  expect_error(ifcb_extract_biovolumes(empty_feature_dir, class_folder), "No feature data files found")

  # Run the function with empty class directory and expect an error
  expect_error(ifcb_extract_biovolumes(feature_folder, empty_class_dir), "No MAT files found")
})

test_that("ifcb_extract_biovolumes handles invalid directories gracefully", {

  # Define invalid directories for features and class
  invalid_feature_dir <- file.path(temp_dir, "invalid_features")
  invalid_class_dir <- file.path(temp_dir, "invalid_class")

  # Run the function with invalid directories and expect an error
  expect_error(ifcb_extract_biovolumes(invalid_feature_dir, invalid_class_dir))
})

test_that("ifcb_extract_biovolumes calculates carbon content correctly for diatoms and non-diatoms", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://marinespecies.org")

  # Use test data to check specific calculations
  biovolume_df <- ifcb_extract_biovolumes(feature_folder, class_folder, micron_factor = 1 / 3.4, diatom_class = "Bacillariophyceae", threshold = "opt", multiblob = FALSE)

  # Check if diatom classes are identified correctly and carbon is calculated
  diatom_rows <- biovolume_df %>% dplyr::filter(class %in% "Bacillariophyceae")
  expect_true(all(diatom_rows$carbon_pg > 0))

  # Check if non-diatom classes are identified correctly and carbon is calculated
  non_diatom_rows <- biovolume_df %>% dplyr::filter(!class %in% "Bacillariophyceae")
  expect_true(all(non_diatom_rows$carbon_pg > 0))
})

test_that("ifcb_extract_biovolumes manual data correctly", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://marinespecies.org")

  expect_error(ifcb_extract_biovolumes(feature_folder, manual_folder), "class2use must be specified when extracting manual biovolume data")

  # Run the function with test data
  biovolume_df <- ifcb_extract_biovolumes(feature_folder, manual_folder, class2use_file = class2use_file, micron_factor = 1 / 3.4, diatom_class = "Bacillariophyceae", threshold = "opt", multiblob = FALSE)

  # Check that the returned object is a data frame
  expect_s3_class(biovolume_df, "data.frame")

  # Check that the data frame contains the expected columns
  expected_columns <- c("sample", "roi_number", "class", "biovolume_um3", "carbon_pg")
  expect_true(all(expected_columns %in% names(biovolume_df)))

  # Check that the data frame has non-zero rows
  expect_gt(nrow(biovolume_df), 0)

  # Check some specific values (replace with expected values based on your test data)
  # Example: Check if specific sample and roi_number exist in the output
  expect_true("D20220522T003051_IFCB134" %in% biovolume_df$sample)
  expect_true(2 %in% biovolume_df$roi_number)

  # Example: Check if biovolume_um3 and carbon_pg are calculated correctly
  # Replace the following expected values with the actual expected values from your test data
  expected_biovolume_um3 <- 5206.2003  # Example value
  expect_equal(biovolume_df$biovolume_um3[1], expected_biovolume_um3, tolerance = 1e-8)

  expected_carbon_pg <- 668.05635  # Example value
  expect_equal(biovolume_df$carbon_pg[1], expected_carbon_pg, tolerance = 1e-8)
})

test_that("ifcb_extract_biovolumes handles customs classifications correctly", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://marinespecies.org")

  # Define custom list
  class = c("Mesodinium_rubrum", "Mesodinium_rubrum")
  image <- c("D20220522T003051_IFCB134_00002", "D20220522T003051_IFCB134_00003")

  # Run the function with test data
  biovolume_df <- ifcb_extract_biovolumes(feature_folder, custom_classes = class, custom_images = image)

  # Check that the returned object is a data frame
  expect_s3_class(biovolume_df, "data.frame")

  # Check that the data frame contains the expected columns
  expected_columns <- c("sample", "roi_number", "class", "biovolume_um3", "carbon_pg")
  expect_true(all(expected_columns %in% names(biovolume_df)))

  # Check that the data frame has non-zero rows
  expect_gt(nrow(biovolume_df), 0)

  # Check some specific values (replace with expected values based on your test data)
  # Example: Check if specific sample and roi_number exist in the output
  expect_true("D20220522T003051_IFCB134" %in% biovolume_df$sample)
  expect_true(2 %in% biovolume_df$roi_number)

  # Example: Check if biovolume_um3 and carbon_pg are calculated correctly
  # Replace the following expected values with the actual expected values from your test data
  expected_biovolume_um3 <- 5206.2003  # Example value
  expect_equal(biovolume_df$biovolume_um3[1], expected_biovolume_um3, tolerance = 1e-8)

  expected_carbon_pg <- 668.05635  # Example value
  expect_equal(biovolume_df$carbon_pg[1], expected_carbon_pg, tolerance = 1e-8)
})

test_that("ifcb_extract_biovolumes throws expected errors and warnings", {
  # Check for internet connection and skip the test if offline
  skip_if_offline()
  skip_on_cran()
  skip_if_resource_unavailable("https://marinespecies.org")

  # Define custom list
  class = c("Mesodinium_rubrum", "Mesodinium_rubrum")
  image <- c("D20220522T003051_IFCB134_00002", "D20220522T003051_IFCB134_00003")

  expect_warning(ifcb_extract_biovolumes(feature_folder, class_folder, custom_images = image, verbose = FALSE),
                 "Both `mat_files` and `custom_images/custom_classes` were provided")

  expect_error(ifcb_extract_biovolumes(feature_folder, verbose = FALSE),
               "No classification information supplied")

  expect_error(ifcb_extract_biovolumes("not_a_dir", class_folder, verbose = FALSE),
               "The specified file or directory does not exist")

  expect_error(ifcb_extract_biovolumes(0, class_folder, verbose = FALSE),
               "feature_files must be a character vector of filenames")
})

unlink(temp_dir, recursive = TRUE)
