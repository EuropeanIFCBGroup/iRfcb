utils::globalVariables(c("longitude", "latitude", "in_basin"))
#' Check if Points are in a Specific Sea Basin
#'
#' This function checks if vectors of latitude and longitude points are within a user-supplied sea basin.
#' The Baltic Sea basins are included as a pre-packaged shapefile in the `iRfcb` package.
#'
#' @param latitudes A numeric vector of latitude points.
#' @param longitudes A numeric vector of longitude points.
#' @param plot A boolean indicating whether to plot the points and the sea basin. Default is FALSE.
#' @param shape_file The absolute path to a custom polygon shapefile in WGS84 (EPSG:4326) that represents the specific sea basin.
#'                   Default is a land-buffered shapefile of the Baltic Sea basins, included in the `iRfcb` package.
#'
#' @return A logical vector indicating whether each point is within the specified sea basin, or a plot with the points and basins if `plot = TRUE`.
#'
#' @details This function reads a pre-packaged shapefile of the Baltic Sea Basin from the `iRfcb` package by default, or a user-supplied
#'          shapefile if provided. It sets the CRS, transforms the CRS to WGS84 (EPSG:4326) if necessary, and checks if the given points
#'          fall within the specified sea basin. Optionally, it plots the points and the sea basin polygons together.
#'
#' @examples
#' # Define example latitude and longitude vectors
#' latitudes <- c(55.337, 54.729, 56.311, 57.975)
#' longitudes <- c(12.674, 14.643, 12.237, 10.637)
#'
#' # Check if the points are in the Baltic Sea Basin
#' points_in_the_baltic <- ifcb_is_in_basin(latitudes, longitudes)
#' print(points_in_the_baltic)
#'
#' # Plot the points and the basin
#' ifcb_is_in_basin(latitudes, longitudes, plot = TRUE)
#'
#' @export
ifcb_is_in_basin <- function(latitudes, longitudes, plot = FALSE, shape_file = NULL) {

  if (is.null(shape_file)) {
    # Directory to extract files
    exdir <- tempdir()  # Temporary directory

    # Extract the files
    unzip(system.file("exdata/baltic_sea_polygon.zip", package = "iRfcb"), exdir = exdir)

    # Get coastline and land data within the bounding box
    basins <- sf::st_read(file.path(exdir, "baltic_sea_buffered.shp"), quiet = TRUE)
  } else {
    basins <- sf::st_read(shape_file, quiet = TRUE)
  }

  # Ensure the shapefile is in WGS84 (EPSG:4326)
  if (sf::st_crs(basins) != sf::st_crs(4326)) {
    warning("The CRS of the shapefile is not in WGS84 (EPSG:4326). Transforming CRS to WGS84.")
    basins <- sf::st_transform(basins, 4326)
  }

  # Create a data frame of the points
  points_df <- data.frame(longitude = longitudes, latitude = latitudes)

  # Convert the data frame to an sf object
  points_sf <- sf::st_as_sf(points_df, coords = c("longitude", "latitude"), crs = sf::st_crs(basins))

  # Check which points are within the filtered basins
  points_in_basins <- sf::st_within(points_sf, basins, sparse = FALSE)

  # Create a vector of TRUE/FALSE labels for each point
  labels <- apply(points_in_basins, 1, any)

  # Plot the data
  if (plot) {
    points_df$in_basin <- labels
    plot_obj <- ggplot() +
      geom_sf(data = basins, fill = "lightblue", color = "black", alpha = 0.5) +
      geom_sf(data = points_sf, aes(color = as.factor(labels)), size = 2) +
      scale_color_manual(values = c("TRUE" = "blue", "FALSE" = "red")) +
      labs(title = ifelse(is.null(shape_file), "Points in land-buffered Baltic Sea Basins", "Points in basin"),
           color = "In Basin") +
      ylim(c(min(latitudes)-1, max(latitudes)+1)) +
      xlim(c(min(longitudes)-1, max(longitudes)+1)) +
      theme_minimal()
  }

  # Return a logical vector indicating whether each point is in a basin, or the plot if requested
  if (plot) {
    return(plot_obj)
  } else {
    return(labels)
  }
}
