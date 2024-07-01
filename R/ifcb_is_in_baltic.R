#' Check if Points are in the Baltic Sea Basin
#'
#' This function checks if vectors of latitude and longitude points are within the
#' Baltic Sea (including Öresund) using a pre-packaged shapefile included in the `iRfcb` package.
#'
#' @param latitudes A numeric vector of latitude points.
#' @param longitudes A numeric vector of longitude points.
#'
#' @return A logical vector indicating whether each point is in the Baltic Sea Basin.
#'
#' @details This function extracts a pre-packaged shapefile of the Baltic Sea Basin from the `iRfcb` package, sets the CRS,
#' transforms the CRS to WGS84 (EPSG:4326), and checks if the given points fall within the Baltic Sea Basin.
#'
#' @examples
#' # Define example latitude and longitude vectors
#' latitudes <- c(55.337, 54.729, 56.311, 57.975)
#' longitudes <- c(12.674, 14.643, 12.237, 10.637)
#'
#' # Check if the points are in the Baltic Sea Basin
#' result <- ifcb_is_in_baltic(latitudes, longitudes)
#' print(result)
#'
#' @importFrom sf st_read st_transform st_as_sf st_crs st_within
#' @importFrom zip unzip
#' @export
ifcb_is_in_baltic <- function(latitudes, longitudes) {
  # Directory to extract files
  exdir <- tempdir()  # Temporary directory

  # Extract the files
  unzip(system.file("exdata/baltic_sea_polygon.zip", package = "iRfcb"), exdir = exdir)

  # Get coastline and land data within the bounding box
  basins <- sf::st_read(file.path(exdir, "baltic_sea.shp"), quiet = TRUE)

  # Change CRS
  basins <- sf::st_transform(basins, 4326)

  # Create a data frame of the points
  points_df <- data.frame(longitude = longitudes, latitude = latitudes)

  # Convert the data frame to an sf object
  points_sf <- sf::st_as_sf(points_df, coords = c("longitude", "latitude"), crs = sf::st_crs(basins))

  # Check which points are within the filtered basins
  points_in_basins <- sf::st_within(points_sf, basins, sparse = FALSE)

  # Return a logical vector indicating whether each point is in a basin
  return(apply(points_in_basins, 1, any))
}
