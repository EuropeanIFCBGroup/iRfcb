test_that("ifcb_is_near_land works correctly", {
  # Skip slow test on CRAN
  skip_on_cran()

  # Define test latitudes and longitudes
  latitudes <- c(62.500353, 58.964498, 57.638725, 56.575338, NA, 60.0)
  longitudes <- c(17.845993, 20.394418, 18.284523, 16.227174, 15.0, NA)

  # Directory to extract files
  exdir <- file.path(tempdir(), "ifcb_is_near_land")  # Temporary directory

  # Extract the files
  unzip(system.file("exdata/baltic_sea_polygon.zip", package = "iRfcb"), exdir = exdir)

  # Path to the shapefile in the extracted test data
  shape_file <- file.path(exdir, "baltic_sea_buffered.shp")

  # Test with default parameters
  near_land_default <- ifcb_is_near_land(latitudes, longitudes)
  expect_type(near_land_default, "logical")
  expect_length(near_land_default, length(latitudes))
  expect_true(all(is.na(near_land_default[is.na(latitudes)])))

  # Test with provided shape file
  near_land_shape <- suppressWarnings(ifcb_is_near_land(latitudes, longitudes, shape = shape_file))
  expect_type(near_land_shape, "logical")
  expect_length(near_land_shape, length(latitudes))
  expect_true(all(is.na(near_land_shape[is.na(latitudes)])))

  # Test with different buffer distance
  near_land_buffer <- ifcb_is_near_land(latitudes, longitudes, distance = 1000)
  expect_type(near_land_buffer, "logical")
  expect_length(near_land_buffer, length(latitudes))
  expect_true(all(is.na(near_land_buffer[is.na(latitudes)])))

  # Check that positions are near land correctly identified (dummy check)
  # These values should be manually verified with known data
  expected_near_land <- c(TRUE, FALSE, TRUE, FALSE, NA, NA)
  expect_equal(near_land_default, expected_near_land)

  # Cleanup temporary files
  unlink(exdir, recursive = TRUE)
})
