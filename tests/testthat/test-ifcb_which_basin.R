# Define example latitude and longitude vectors for testing
latitudes <- c(55.337, 54.729, 56.311, 57.975)
longitudes <- c(12.674, 14.643, 12.237, 10.637)

# Expected results (replace with the actual expected basins for these coordinates)
expected_basins <- c("13 - Arkona Basin", "12 - Bornholm Basin",
                     "16 - Kattegat","17 - Skagerrak")

test_that("ifcb_which_basin correctly identifies basins", {
  # Call the function
  result <- ifcb_which_basin(latitudes, longitudes)

  # Check that the result is as expected
  expect_equal(result, expected_basins)
})

test_that("ifcb_which_basin correctly handles the default shapefile", {
  # Call the function without a custom shapefile
  result <- ifcb_which_basin(latitudes, longitudes)

  # Check that the result is a character vector
  expect_true(is.character(result))

  # Check the length of the result
  expect_equal(length(result), length(latitudes))
})

test_that("ifcb_which_basin returns a ggplot object when plot = TRUE", {
  # Call the function with plot = TRUE
  plot_result <- ifcb_which_basin(latitudes, longitudes, plot = TRUE)

  # Check that the result is a ggplot object
  expect_true(inherits(plot_result, "ggplot"))
})

test_that("ifcb_which_basin correctly handles a custom shapefile", {
  skip_on_cran()

  # Directory to extract files
  exdir <- file.path(tempdir(), "ifcb_which_basin")  # Temporary directory

  # Extract the files
  unzip(system.file("exdata/baltic_sea_polygon.zip", package = "iRfcb"), exdir = exdir)

  # Test a different shape-file
  custom_shape_file <- file.path(exdir, "baltic_sea_buffered.shp")
  custom_shape_file_4324 <- file.path(exdir, "baltic_sea_buffered_4324.shp")

  # Change the CRS
  custom_shape <- sf::st_read(custom_shape_file)
  custom_shape <- sf::st_transform(custom_shape, 4324)
  sf::st_write(custom_shape, custom_shape_file_4324)

  # Run the test
  expect_warning(ifcb_which_basin(latitudes, longitudes, shape_file = custom_shape_file_4324))
  result <- ifcb_which_basin(latitudes, longitudes, shape_file = custom_shape_file)

  # Check that the result is a character vector
  expect_true(is.list(result))

  # Check the length of the result
  expect_equal(length(result), length(latitudes))

  unlink(exdir, recursive = TRUE)
})
