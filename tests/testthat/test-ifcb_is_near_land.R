test_that("ifcb_is_near_land works correctly", {
  # Skip slow test on CRAN
  skip_on_cran()

  # Define test latitudes and longitudes
  latitudes <- c(62.500353, 58.964498, 57.638725, 56.575338, NA, 60.0)
  longitudes <- c(17.845993, 20.394418, 18.284523, 16.227174, 15.0, NA)

  # Test with default parameters
  near_land_default <- ifcb_is_near_land(latitudes, longitudes)
  expect_type(near_land_default, "logical")
  expect_length(near_land_default, length(latitudes))
  expect_true(all(is.na(near_land_default[is.na(latitudes)])))

  # Check that positions are near land correctly identified (dummy check)
  expected_near_land <- c(TRUE, FALSE, TRUE, FALSE, NA, NA)
  expect_equal(near_land_default, expected_near_land)
})

test_that("ifcb_is_near_land works correctly with EEA data", {

  download_url <- "https://marine.discomap.eea.europa.eu"

  # Skip slow test on CRAN
  skip_on_cran()
  skip_if_offline()
  skip_if_resource_unavailable(download_url)

  # Define test latitudes and longitudes
  latitudes <- c(62.500353, 58.964498, 57.638725, 56.575338, NA, 60.0)
  longitudes <- c(17.845993, 20.394418, 18.284523, 16.227174, 15.0, NA)

  # Test with default parameters
  near_land_eea <- ifcb_is_near_land(latitudes, longitudes, source = "eea")
  expect_type(near_land_eea, "logical")
  expect_length(near_land_eea, length(latitudes))
  expect_true(all(is.na(near_land_eea[is.na(latitudes)])))

  # Check that positions are near land correctly identified (dummy check)
  expected_near_land <- c(TRUE, FALSE, TRUE, TRUE, NA, NA)
  expect_equal(near_land_eea, expected_near_land)
})

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

  # Test with provided shape file
  near_land_shape <- suppressWarnings(ifcb_is_near_land(latitudes, longitudes, shape = shape_file))
  expect_type(near_land_shape, "logical")
  expect_length(near_land_shape, length(latitudes))
  expect_true(all(is.na(near_land_shape[is.na(latitudes)])))

  # Test with different buffer distance
  near_land_buffer <- suppressWarnings(ifcb_is_near_land(latitudes, longitudes, shape = shape_file, distance = 1000))
  expect_type(near_land_buffer, "logical")
  expect_length(near_land_buffer, length(latitudes))
  expect_true(all(is.na(near_land_buffer[is.na(latitudes)])))

  lifecycle::expect_deprecated(ifcb_is_near_land(latitudes, longitudes, shape = shape_file, utm_zone = 33))

  # Check that plotting works
  near_land_plot <- ifcb_is_near_land(latitudes, longitudes, shape = shape_file, plot = TRUE)
  expect_s3_class(near_land_plot, "gg")

  # Cleanup temporary files
  unlink(exdir, recursive = TRUE)
})
