utils::globalVariables(c("longitude", "latitude"))

#' Determine if Points are in a Specified Sea Basin
#'
#' This function identifies which sub-basin a set of latitude and longitude points belong to, using a user-specified or default shapefile.
#' The default shapefile includes the Baltic Sea, Kattegat, and Skagerrak basins and is included in the `iRfcb` package.
#'
#' @param latitudes A numeric vector of latitude points.
#' @param longitudes A numeric vector of longitude points.
#' @param plot A boolean indicating whether to plot the points along with the sea basins. Default is FALSE.
#' @param shape_file The absolute path to a custom polygon shapefile in WGS84 (EPSG:4326) that represents the sea basin.
#'                   Defaults to the Baltic Sea, Kattegat, and Skagerrak basins included in the `iRfcb` package.
#'
#' @return A vector indicating the basin each point belongs to, or a ggplot object if `plot = TRUE`.
#'
#' @details This function reads a pre-packaged shapefile of the Baltic Sea, Kattegat, and Skagerrak basins from the `iRfcb` package by default, or a user-supplied
#'          shapefile if provided. The shapefiles originate from SHARK (https://shark.smhi.se/). It sets the CRS, transforms the CRS to WGS84 (EPSG:4326) if necessary, and checks if the given points
#'          fall within the specified sea basin. Optionally, it plots the points and the sea basin polygons together.
#'
#' @examples
#' # Define example latitude and longitude vectors
#' latitudes <- c(55.337, 54.729, 56.311, 57.975)
#' longitudes <- c(12.674, 14.643, 12.237, 10.637)
#'
#' # Check in which Baltic sea basin the points are in
#' points_in_the_baltic <- ifcb_which_basin(latitudes, longitudes)
#' print(points_in_the_baltic)
#'
#' # Plot the points and the basins
#' ifcb_which_basin(latitudes, longitudes, plot = TRUE)
#'
#' @export
ifcb_which_basin <- function(latitudes, longitudes, plot = FALSE, shape_file = NULL) {

  if (is.null(shape_file)) {
    # Directory to extract files
    exdir <- tempdir()  # Temporary directory

    # Extract the files
    unzip(system.file("exdata/baltic_sea_basins.zip", package = "iRfcb"), exdir = exdir)

    # Get coastline and land data within the bounding box
    basins <- sf::st_read(file.path(exdir, "shark_sea_basins.shp"), quiet = TRUE)
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

  # Determine the basin for each point
  basin_names <- apply(points_in_basins, 1, function(row) {
    if (any(row)) {
      basins$basin[which(row)]
    } else {
      NA
    }
  })

  # Plot the data
  if (plot) {
    points_df$in_basin <- basin_names
    plot_obj <- ggplot() +
      geom_sf(data = basins, fill = "lightblue", color = "black", alpha = 0.5) +
      geom_sf(data = points_sf, aes(color = as.factor(basin_names)), size = 2) +
      labs(title = ifelse(is.null(shape_file), "Points in Baltic Sea sub-basins", "Points in basin"),
           color = "Sea basin") +
      ylim(c(min(latitudes)-1, max(latitudes)+1)) +
      xlim(c(min(longitudes)-1, max(longitudes)+1)) +
      theme_minimal() +
      # Set white background and ensure plot background is white
      theme(
        panel.background = element_rect(fill = "white", color = NA),
        plot.background = element_rect(fill = "white", color = NA)
      )
  }

  # Return a logical vector indicating whether each point is in a basin, or the plot if requested
  if (plot) {
    plot_obj
  } else {
    basin_names
  }
}
