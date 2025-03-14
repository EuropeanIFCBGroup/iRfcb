test_that("ifcb_extract_pngs works correctly", {
  skip_on_cran()

  # Define paths to the test data
  test_data_zip <- test_path("test_data/test_data.zip")
  temp_dir <- file.path(tempdir(), "ifcb_extract_pngs")
  unzip(test_data_zip, exdir = temp_dir)

  # Path to the .roi and .adc files in the extracted test data
  roi_file <- file.path(temp_dir, "test_data", "data", "D20220522T003051_IFCB134.roi")
  adc_file <- file.path(temp_dir, "test_data", "data", "D20220522T003051_IFCB134.adc")

  # Create dummy ADC data if it doesn't exist (in case)
  if (!file.exists(adc_file)) {
    write.csv(data.frame(V16 = c(64, 128), V17 = c(64, 128), V18 = c(0, 4096)),
              adc_file, row.names = FALSE, col.names = FALSE)
  }

  # Output folder for PNG images
  out_folder <- file.path(temp_dir, "output")

  # Ensure the output directory exists
  dir.create(out_folder, showWarnings = FALSE, recursive = TRUE)

  # Call the function to extract PNG images
  ifcb_extract_pngs(roi_file, out_folder = out_folder, ROInumbers = c(1, 2), verbose = FALSE)
  ifcb_extract_pngs(roi_file, out_folder = out_folder, ROInumbers = c(1, 2), verbose = TRUE)

  # Check that the expected PNG files are created
  expected_files <- c(
    file.path(out_folder, "D20220522T003051_IFCB134", "D20220522T003051_IFCB134_00002.png")
  )

  for (file in expected_files) {
    expect_true(file.exists(file), info = paste("File does not exist:", file))
  }

  # Cleanup temporary files
  unlink(temp_dir, recursive = TRUE)
})
