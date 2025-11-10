test_that("ifcb_get_ferrybox_data works correctly with valid inputs", {
  # Create a temporary directory
  temp_dir <- file.path(tempdir(), "ifcb_get_ferrybox_data")

  if (!dir.exists(temp_dir)) {
    dir.create(temp_dir, recursive = TRUE)
  }

  # Path to the example ferrybox file
  example_file <- system.file("exdata/example_ferrybox.txt", package = "iRfcb")
  expect_true(file.exists(example_file))

  # Define the new file name and copy it to the temporary directory
  new_file_name <- "SveaFB_38059_20220501000100_20220531235800_OK.txt"
  new_file_path <- file.path(temp_dir, new_file_name)
  file.copy(example_file, new_file_path)
  expect_true(file.exists(new_file_path))

  # Define test timestamps
  test_timestamps <- as.POSIXct(c("2022-05-22 00:04:39", "2022-05-22 00:30:51"), tz = "UTC")

  # Run the function
  result <- ifcb_get_ferrybox_data(test_timestamps, temp_dir)

  # Verify the structure and content of the result
  expect_s3_class(result, "data.frame")
  expect_named(result, c("timestamp", "gpsLatitude", "gpsLongitude"))

  # Verify that the timestamps in the result match the input timestamps
  expect_equal(result$timestamp, test_timestamps)

  # Check that the first timestamp gets a position and the second does not
  expect_true(!is.na(result$gpsLatitude[1]))
  expect_true(!is.na(result$gpsLongitude[1]))
  expect_true(is.na(result$gpsLatitude[2]))
  expect_true(is.na(result$gpsLongitude[2]))

  # Clean up temporary files
  unlink(temp_dir, recursive = TRUE)
})

test_that("ifcb_get_ferrybox_data handles missing ferrybox folder", {
  # Define test timestamps
  test_timestamps <- as.POSIXct("2022-05-22 00:04:39", tz = "UTC")

  # Run the function with a non-existent folder
  expect_error(ifcb_get_ferrybox_data(test_timestamps, "non_existent_folder"),
               "The specified ferrybox folder does not exist.")
})

test_that("ifcb_get_ferrybox_data handles no ferrybox files in folder", {
  # Create a temporary directory
  temp_dir <- file.path(tempdir(), "ifcb_get_ferrybox_data")

  if (!dir.exists(temp_dir)) {
    dir.create(temp_dir, recursive = TRUE)
  }

  # Define test timestamps
  test_timestamps <- as.POSIXct("2022-05-22 00:04:39", tz = "UTC")

  # Run the function with an empty folder
  expect_error(ifcb_get_ferrybox_data(test_timestamps, temp_dir),
               "No .txt files found in the specified ferrybox folder.")

  # Clean up temporary files
  unlink(temp_dir, recursive = TRUE)
})

test_that("ifcb_get_ferrybox_data handles no matching ship name", {
  # Create a temporary directory
  temp_dir <- file.path(tempdir(), "ifcb_get_ferrybox_data")

  if (!dir.exists(temp_dir)) {
    dir.create(temp_dir, recursive = TRUE)
  }

  # Path to the example ferrybox file
  example_file <- system.file("exdata/example_ferrybox.txt", package = "iRfcb")
  expect_true(file.exists(example_file))

  # Define the new file name and copy it to the temporary directory
  new_file_name <- "OtherShip_38059_20220501000100_20220531235800_OK.txt"
  new_file_path <- file.path(temp_dir, new_file_name)
  file.copy(example_file, new_file_path)
  expect_true(file.exists(new_file_path))

  # Define test timestamps
  test_timestamps <- as.POSIXct("2022-05-22 00:04:39", tz = "UTC")

  # Run the function with a ship name that doesn't match
  expect_error(ifcb_get_ferrybox_data(test_timestamps, temp_dir),
               "No ferrybox files matching the specified ship name were found.")

  # Clean up temporary files
  unlink(temp_dir, recursive = TRUE)
})

test_that("ifcb_get_ferrybox_data handles mistyped timestamps", {
  # Create a temporary directory
  temp_dir <- file.path(tempdir(), "ifcb_get_ferrybox_data")

  if (!dir.exists(temp_dir)) {
    dir.create(temp_dir, recursive = TRUE)
  }

  # Define test timestamps
  test_timestamps <- "This is not a timestamp"

  # Run the function with an empty folder
  expect_error(ifcb_get_ferrybox_data(test_timestamps, temp_dir),
               "The 'timestamps' argument must be a vector of POSIXct timestamps.")

  # Clean up temporary files
  unlink(temp_dir, recursive = TRUE)
})

test_that("ifcb_get_ferrybox_data handles empty ferrybox files", {
  # Create a temporary directory
  temp_dir <- file.path(tempdir(), "ifcb_get_ferrybox_data")

  if(!dir.exists(temp_dir)) {
    dir.create(temp_dir, recursive = TRUE)
  }

  # Create a corrupted ferrybox file
  corrupted_file_name <- "SveaFB_38059_20220501000100_20220531235800_OK.txt"
  corrupted_file_path <- file.path(temp_dir, corrupted_file_name)
  create_temp_ferrybox_file(corrupted_file_path, "corrupted content")

  # Define test timestamps
  test_timestamps <- as.POSIXct("2022-05-22 00:04:39", tz = "UTC")

  # Run the function
  expect_error(result <- ifcb_get_ferrybox_data(test_timestamps, temp_dir),
                 "No valid ferrybox data could be read from the filtered files.")

  # Clean up temporary files
  unlink(temp_dir, recursive = TRUE)
})

test_that("ifcb_get_ferrybox_data handles no matching GPS data", {
  # Create a temporary directory
  temp_dir <- file.path(tempdir(), "ifcb_get_ferrybox_data")

  if(!dir.exists(temp_dir)) {
    dir.create(temp_dir, recursive = TRUE)
  }

  # Path to the example ferrybox file
  example_file <- system.file("exdata/example_ferrybox.txt", package = "iRfcb")
  expect_true(file.exists(example_file))

  # Define the new file name and copy it to the temporary directory
  new_file_name <- "SveaFB_38059_20220501000100_20220531235800_OK.txt"
  new_file_path <- file.path(temp_dir, new_file_name)
  file.copy(example_file, new_file_path)
  expect_true(file.exists(new_file_path))

  # Define test timestamps outside the range of the ferrybox data
  test_timestamps <- as.POSIXct("2023-01-01 00:00:00", tz = "UTC")

  # Run the function
  expect_error(result <- ifcb_get_ferrybox_data(test_timestamps, temp_dir),
               "No ferrybox files contain data within the provided timestamps.")

  # Clean up temporary files
  unlink(temp_dir, recursive = TRUE)
})

