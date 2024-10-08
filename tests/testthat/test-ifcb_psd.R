test_that("ifcb_psd works correctly", {
  # Create a temporary directory
  temp_dir <- tempdir()

  # Define the path to the test data zip file
  test_data_zip <- test_path("test_data/test_data.zip")
  expect_true(file.exists(test_data_zip))

  # Unzip the test data to the temporary directory
  unzip(test_data_zip, exdir = temp_dir)

  # Define the paths to the test data subfolders and files
  feature_folder <- file.path(temp_dir, "test_data/features")
  hdr_folder <- file.path(temp_dir, "test_data/data")
  plot_folder <- file.path(temp_dir, "psd_plots")
  output_file <- file.path(temp_dir, "psd_output")

  # List all files in the directory
  files <- dir(hdr_folder, full.names = TRUE)

  # Loop through each file
  for (file_path in files) {
    # Extract the base name of the file
    file_name <- basename(file_path)

    # Extract the date part of the filename using regex
    date_match <- regmatches(file_name, regexpr("D\\d{8}", file_name))

    if (length(date_match) > 0) {
      # Extract the year from the date (e.g., 2022 from D20220522)
      year <- substring(date_match, 2, 5)

      # Create the subfolder paths
      year_folder <- file.path(hdr_folder, year)
      date_folder <- file.path(year_folder, date_match)

      # Create the subfolders if they don't exist
      if (!dir.exists(date_folder)) {
        if (!dir.exists(year_folder)) {
          dir.create(year_folder)
        }
        dir.create(date_folder)
      }

      # Move the file to the subfolder
      new_file_path <- file.path(date_folder, file_name)
      fs::file_move(file_path, new_file_path)
    }
  }

  # Remove unnecessary files
  unlink(file.path(hdr_folder, "2023"), recursive = TRUE)
  file.remove(file.path(hdr_folder, "2022", "D20220522", "D20220522T000439_IFCB134.adc"))
  file.remove(file.path(hdr_folder, "2022", "D20220522", "D20220522T000439_IFCB134.hdr"))

  # Ensure the test data directories exist
  expect_true(dir.exists(feature_folder))
  expect_true(dir.exists(hdr_folder))

  # Create a temporary virtual environment
  venv_dir <- "~/.virtualenvs/iRfcb"

  # Install a temporary virtual environment
  if (reticulate::virtualenv_exists(venv_dir)) {
    reticulate::use_virtualenv(venv_dir, required = TRUE)
  } else {
    reticulate::virtualenv_create(venv_dir, requirements = system.file("python", "requirements.txt", package = "iRfcb"))
    reticulate::use_virtualenv(venv_dir, required = TRUE)
  }

  # Run the function
  result <- ifcb_psd(
    feature_folder = feature_folder,
    hdr_folder = file.path(hdr_folder, "2022"),
    save_data = TRUE,
    output_file = output_file,
    plot_folder = plot_folder,
    use_marker = FALSE,
    start_fit = 10,
    r_sqr = 0.5,
    beads = 10 ** 12,
    bubbles = 150,
    incomplete = c(1500, 3),
    missing_cells = 0.7,
    biomass = 1000,
    bloom = 5,
    humidity = NULL
  )

  # Verify that the output list contains data, fits, and flags
  expect_true("data" %in% names(result))
  expect_true("fits" %in% names(result))
  expect_true("flags" %in% names(result))

  # Verify that the data, fits, and flags are not empty
  expect_true(nrow(result$data) > 0)
  expect_true(nrow(result$fits) > 0)
  expect_true(is.null(result$flags) || nrow(result$flags) > 0)

  # Verify that the output CSV file is created
  expect_true(file.exists(paste0(output_file, "_fits.csv")))
  expect_true(file.exists(paste0(output_file, "_data.csv")))
  expect_true(file.exists(paste0(output_file, "_flags.csv")))

  # Verify that plot images are created in the plot folder
  plot_files <- list.files(plot_folder, pattern = "\\.png$", full.names = TRUE, recursive = TRUE)
  expect_true(length(plot_files) > 0)

  # Clean up temporary files
  # unlink(venv_dir, recursive = TRUE)
  unlink(temp_dir, recursive = TRUE)
})
