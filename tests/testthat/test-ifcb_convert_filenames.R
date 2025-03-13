test_that("ifcb_convert_filenames correctly extracts timestamp components", {
  # Define example IFCB filenames for testing
  filenames <- c("D20230314T001205_IFCB134", "D20230615T123045_IFCB135")

  # Expected results
  expected_data <- data.frame(
    sample = c("D20230314T001205_IFCB134", "D20230615T123045_IFCB135"),
    timestamp = as.POSIXct(c("2023-03-14 00:12:05", "2023-06-15 12:30:45"), format = "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    date = as.Date(c("2023-03-14", "2023-06-15")),
    year = c(2023, 2023),
    month = c(3, 6),
    day = c(14, 15),
    time = c("00:12:05", "12:30:45"),
    ifcb_number = c("IFCB134", "IFCB135"),
    stringsAsFactors = FALSE
  )

  expected_data <- readr::type_convert(expected_data, col_types = readr::cols())

  # Call the function
  result <- ifcb_convert_filenames(filenames)

  # Check that the result is a data frame
  expect_true(is.data.frame(result))

  # Check that the result matches the expected data
  expect_equal(result, expected_data)
})

test_that("ifcb_convert_filenames correctly handles filenames with ROI", {

  # Define example IFCB filenames with ROI for testing
  filenames_with_roi <- c("D20230314T001205_IFCB134_001", "D20230615T123045_IFCB135_002")

  # Expected results
  expected_data <- data.frame(
    sample = c("D20230314T001205_IFCB134", "D20230615T123045_IFCB135"),
    timestamp = as.POSIXct(c("2023-03-14 00:12:05", "2023-06-15 12:30:45"), format = "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    date = as.Date(c("2023-03-14", "2023-06-15")),
    year = c(2023, 2023),
    month = c(3, 6),
    day = c(14, 15),
    time = c("00:12:05", "12:30:45"),
    ifcb_number = c("IFCB134", "IFCB135"),
    stringsAsFactors = FALSE
  )

  expected_data <- readr::type_convert(expected_data, col_types = readr::cols())

  # Expected results with ROI
  expected_data_with_roi <- expected_data
  expected_data_with_roi$roi <- c(1, 2)

  # Call the function
  result <- ifcb_convert_filenames(filenames_with_roi)

  # Check that the result is a data frame
  expect_true(is.data.frame(result))

  # Check that the result matches the expected data with ROI
  expect_equal(result, expected_data_with_roi)
})

test_that("ifcb_convert_filenames handles empty input", {
  result <- ifcb_convert_filenames(character(0))
  expect_true(is.data.frame(result))
  expect_equal(nrow(result), 0)
})

test_that("ifcb_convert_filenames handles incorrect format input", {
  incorrect_filenames <- c("20230314T001205_IFCB134", "D20230615_IFCB135")
  expect_error(ifcb_convert_filenames(incorrect_filenames), "Error")
})
