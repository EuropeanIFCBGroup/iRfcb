test_that("ifcb_psd works correctly", {
  # Skip if Python is not available
  skip_if_no_scipy()
  skip_if_no_pandas()
  skip_if_no_matplotlib()
  skip_on_cran()

  # Skip if Python is not available
  skip_if(Sys.getenv("SKIP_PYTHON_TESTS") == "true",
          "Skipping Python-dependent tests: missing Python packages or running on CRAN.")

  # Create a temporary directory
  temp_dir <- file.path(tempdir(), "ifcb_psd")

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
      success <- file.copy(file_path, new_file_path)
      if (success) unlink(file_path)
    }
  }

  # Remove unnecessary files
  unlink(file.path(hdr_folder, "2023"), recursive = TRUE)
  file.remove(file.path(hdr_folder, "2022", "D20220522", "D20220522T000439_IFCB134.adc"))
  file.remove(file.path(hdr_folder, "2022", "D20220522", "D20220522T000439_IFCB134.hdr"))

  # Ensure the test data directories exist
  expect_true(dir.exists(feature_folder))
  expect_true(dir.exists(hdr_folder))

  # Run the function
  result <- ifcb_psd(
    feature_folder = feature_folder,
    hdr_folder = file.path(hdr_folder, "2022"),
    bins = "D20220522T003051_IFCB134",
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
    humidity = 99,
    use_plot_subfolders = TRUE
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

test_that("ifcb_psd fails gracefully if folders do not exist", {
  expect_error(ifcb_psd("not_a_dir", tempdir()),
               "does not exist")

  if (!dir.exists(tempdir())) {
    dir.create(tempdir(), recursive = TRUE)
  }

  expect_error(ifcb_psd(tempdir(), "not_a_dir"),
               "does not exist")
})

test_that("psd_flag_args keeps only the thresholds that were set", {
  # Every flag threshold defaults to NULL; passing those on to Python made
  # get_flags() compare against None and fail.
  expect_length(psd_flag_args(), 0)

  args <- psd_flag_args(bubbles = 150, incomplete = c(1500, 3), humidity = 70)
  expect_named(args, c("bubbles", "incomplete", "humidity"))
  expect_identical(args$incomplete, c(1500L, 3L))
  expect_identical(args$humidity, 70)
})

test_that("psd_plot_subfolder uses PSD.OK when a sample has no flag", {
  flags <- dplyr::tibble(sample = "D20220522T003051_IFCB134", flag = "Low R^2")

  # No sample flagged at all: flags is NULL
  expect_equal(psd_plot_subfolder("D20220522T003051_IFCB134", NULL, "plots"),
               file.path("plots", "PSD.OK"))
  expect_equal(psd_plot_subfolder("D20220522T000439_IFCB134", flags, "plots"),
               file.path("plots", "PSD.OK"))
  expect_equal(psd_plot_subfolder("D20220522T003051_IFCB134", flags, "plots"),
               file.path("plots", make.names("Low R^2")))
})

test_that("ifcb_psd runs without flag thresholds and without flagged samples", {
  skip_if_no_scipy()
  skip_if_no_pandas()
  skip_if_no_matplotlib()
  skip_on_cran()
  skip_if(Sys.getenv("SKIP_PYTHON_TESTS") == "true",
          "Skipping Python-dependent tests: missing Python packages or running on CRAN.")

  temp_dir <- tempfile("ifcb_psd_defaults_")
  hdr_folder <- file.path(temp_dir, "data", "D20220522")
  feature_folder <- file.path(temp_dir, "features")
  plot_folder <- file.path(temp_dir, "plots")
  dir.create(hdr_folder, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)

  unzip(test_path("test_data/test_data.zip"),
        files = c("test_data/data/D20220522T003051_IFCB134.hdr",
                  "test_data/data/D20220522T003051_IFCB134.adc"),
        exdir = hdr_folder, junkpaths = TRUE)
  unzip(test_path("test_data/test_data.zip"),
        files = "test_data/features/D20220522T003051_IFCB134_fea_v2.csv",
        exdir = feature_folder, junkpaths = TRUE)

  # Every flag threshold left at its NULL default
  psd <- suppressMessages(ifcb_psd(feature_folder, file.path(temp_dir, "data")))
  expect_named(psd, c("data", "fits", "flags"))

  # No sample is flagged, so `flags` is NULL and the plot goes to PSD.OK
  psd <- suppressMessages(ifcb_psd(feature_folder, file.path(temp_dir, "data"),
                                   plot_folder = plot_folder, r_sqr = -Inf))
  expect_null(psd$flags)
  expect_true(file.exists(file.path(plot_folder, "PSD.OK", "D20220522T003051_IFCB134.png")))
})
