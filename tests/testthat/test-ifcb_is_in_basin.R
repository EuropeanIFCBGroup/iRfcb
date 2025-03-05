test_that("ifcb_is_in_basin works with default Baltic Sea shapefile", {
  # Define example latitude and longitude vectors
  latitudes <- c(55.337, 54.729, 56.311, 57.975, 59.123)
  longitudes <- c(12.674, 14.643, 12.237, 10.637, 17.654)

  # Check if the points are in the Baltic Sea Basin
  points_in_the_baltic <- ifcb_is_in_basin(latitudes, longitudes)

  # Expected results (assuming based on actual shapefile)
  expected_results <- c(TRUE, TRUE, FALSE, FALSE, TRUE)  # Adjust based on actual Baltic Sea boundaries

  # Check if the function returns correct logical vector
  expect_equal(points_in_the_baltic, expected_results)
})

test_that("ifcb_is_in_basin works with a custom shapefile", {
  # Define a custom shapefile path (here we use the same Baltic shapefile for simplicity)
  shape_file <- system.file("exdata/baltic_sea_polygon.zip", package = "iRfcb")
  temp_dir <- file.path(tempdir(), "ifcb_is_in_basin")
  unzip(shape_file, exdir = temp_dir)
  custom_shape_file <- file.path(temp_dir, "baltic_sea_buffered.shp")

  # Define example latitude and longitude vectors
  latitudes <- c(55.337, 54.729, 56.311, 57.975, 59.123)
  longitudes <- c(12.674, 14.643, 12.237, 10.637, 17.654)

  # Check if the points are in the custom shapefile basin
  points_in_custom_basin <- ifcb_is_in_basin(latitudes, longitudes, shape_file = custom_shape_file)

  # Expected results (assuming based on actual shapefile)
  expected_results <- c(TRUE, TRUE, FALSE, FALSE, TRUE)  # Adjust based on actual Baltic Sea boundaries

  # Check if the function returns correct logical vector
  expect_equal(points_in_custom_basin, expected_results)

  # Cleanup temporary files
  unlink(temp_dir, recursive = TRUE)
})

test_that("ifcb_is_in_basin plots correctly", {
  # Define example latitude and longitude vectors
  latitudes <- c(55.337, 54.729, 56.311, 57.975, 59.123)
  longitudes <- c(12.674, 14.643, 12.237, 10.637, 17.654)

  # Generate plot
  plot_obj <- ifcb_is_in_basin(latitudes, longitudes, plot = TRUE)

  # Check if the returned object is a ggplot object
  expect_s3_class(plot_obj, "ggplot")
})

test_that("ifcb_is_in_basin handles invalid inputs gracefully", {
  # Define invalid latitude and longitude vectors
  invalid_latitudes <- c("a", "b", "c")
  invalid_longitudes <- c("x", "y", "z")

  # Check if the function returns an error for invalid inputs
  expect_error(suppressWarnings(ifcb_is_in_basin(invalid_latitudes, invalid_longitudes)), "missing values in coordinates not allowed")
})
