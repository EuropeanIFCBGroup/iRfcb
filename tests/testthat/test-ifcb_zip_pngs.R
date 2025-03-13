test_that("ifcb_zip_pngs works correctly", {
  # Skip slow tests on CRAN
  skip_on_cran()

  # Create a temporary directory
  temp_dir <- file.path(tempdir(), "ifcb_zip_pngs")

  # Define the path to the test data zip file
  test_data_zip <- test_path("test_data/test_data.zip")
  expect_true(file.exists(test_data_zip))

  # Unzip the test data to the temporary directory
  unzip(test_data_zip, exdir = temp_dir)

  # Define the paths to the test data subfolders
  png_folder <- file.path(temp_dir, "test_data/png")
  expect_true(dir.exists(png_folder))

  # Define the path for the zip file to create
  zip_filename <- file.path(temp_dir, "test_output.zip")

  # Create placeholder content for README files
  readme_file <- file.path(temp_dir, "README-template.md")
  writeLines("This is a default README template.\n<DATE>\n<VERSION>\n<E-MAIL>\n<ZIP_NAME>\n<YEAR_START>\n<YEAR_END>\n<YEAR>\n<N_IMAGES>\n<CLASSES>", readme_file)

  # Run the function
  ifcb_zip_pngs(png_folder,
                zip_filename,
                readme_file = readme_file,
                email_address = "test@example.com",
                version = "1.0",
                print_progress = TRUE)

  # Verify that the zip file was created
  expect_true(file.exists(zip_filename))

  # List the contents of the zip file using zip::zip_list
  zip_contents <- zip::zip_list(zip_filename)
  expected_files <- list.files(png_folder, pattern = "\\.png$", full.names = TRUE, recursive = TRUE)

  # Normalize paths to use forward slashes
  temp_dir_fixed <- normalizePath(temp_dir, winslash = "/")
  expected_files <- gsub(paste0(temp_dir_fixed, "/"), "", expected_files)

  # Verify the zip file contains the expected files
  for (file in expected_files) {
    expect_true(basename(file) %in% basename(zip_contents$filename))
  }

  # Run the function with split_zip
  ifcb_zip_pngs(png_folder,
                zip_filename,
                readme_file = readme_file,
                email_address = "test@example.com",
                version = "1.0",
                print_progress = TRUE,
                split_zip = TRUE,
                max_size = 0.0000001)

  # Verify that the zip file was created
  expect_true(file.exists(paste0(tools::file_path_sans_ext(zip_filename), "_part_1.zip")))

  # Run the function with split_zip and a large max_size
  ifcb_zip_pngs(png_folder,
                zip_filename,
                readme_file = readme_file,
                email_address = "test@example.com",
                version = "1.0",
                print_progress = TRUE,
                split_zip = TRUE,
                max_size = 500)

  # Clean up temporary files
  unlink(temp_dir, recursive = TRUE)
})
