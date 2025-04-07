#' Determine if Positions are Near Land
#'
#' Determines whether given positions are near land based on a land polygon shape file.
#' The Natural Earth 1:10m land vectors are downloaded as a default shapefile in `iRfcb`.
#'
#' @param latitudes Numeric vector of latitudes for positions.
#' @param longitudes Numeric vector of longitudes for positions.
#' @param distance Buffer distance in meters around the coastline. Default is 500 m.
#' @param shape Optional path to a shapefile containing coastline polygon data. If provided,
#'   the function will use this shapefile instead of the default Natural Earth 1:10m land vectors.
#'   Using a more detailed shapefile allows for a better estimation of the buffer distance.
#'   For detailed European coastlines, download polygons from the EEA at
#'   \url{https://www.eea.europa.eu/data-and-maps/data/eea-coastline-for-analysis-2/gis-data/eea-coastline-polygon}.
#' @param crs Coordinate reference system (CRS) to use for positions and output.
#'   Default is EPSG code 4326 (WGS84).
#' @param remove_small_islands Logical indicating whether to remove small islands from
#'   the coastline if a custom shapefile is provided. Default is TRUE.
#' @param small_island_threshold Area threshold in square meters below which islands
#'   will be considered small and removed, if remove_small_islands is set to TRUE. Default is 2 square km.
#' @param plot A boolean indicating whether to plot the points, land polygon and buffer. Default is FALSE.
#' @param utm_zone `r lifecycle::badge("deprecated")`
#'
#'    `utm_zone` is now calculated from the median longitude of the input coordinates.
#'
#'
#' @return
#' If `plot = FALSE` (default), a logical vector is returned indicating whether each position
#' is near land or not, with `NA` for positions where coordinates are missing.
#' If `plot = TRUE`, a `ggplot` object is returned showing the land polygon, buffer area,
#' and position points colored by their proximity to land.
#'
#' @details
#' This function calculates a buffered area around the coastline using a polygon shapefile and
#' determines if each input position intersects with this buffer or the landmass itself.
#' By default, it downloads and uses the Natural Earth 1:10m land vector dataset.
#'
#' @examples
#' \dontrun{
#' # Define coordinates
#' latitudes <- c(62.500353, 58.964498, 57.638725, 56.575338)
#' longitudes <- c(17.845993, 20.394418, 18.284523, 16.227174)
#'
#' # Call the function
#' near_land <- ifcb_is_near_land(latitudes, longitudes, distance = 300, crs = 4326)
#'
#' # Print the result
#' print(near_land)
#' }
#'
#' @export
ifcb_is_near_land <- function(latitudes,
                              longitudes,
                              distance = 500,
                              shape = NULL,
                              crs = 4326,
                              remove_small_islands = TRUE,
                              small_island_threshold = 2000000,
                              plot = FALSE,
                              utm_zone = deprecated()) {

  # Warn the user if utm_zone is used
  if (lifecycle::is_present(utm_zone)) {

    # Signal the deprecation to the user
    lifecycle::deprecate_warn("0.5.0", "iRfcb::ifcb_annotate_batch(utm_zone = )",
                              details = "utm_zone is now calculated from the median longitude of the input coordinates.")
  }

  # Check for NAs in latitudes and longitudes
  na_positions <- is.na(latitudes) | is.na(longitudes)

  # Create a result vector initialized to NA
  result <- rep(NA, length(latitudes))

  # If all positions are NA, return the result early
  if (all(na_positions)) {
    return(result)
  }

  # Filter out NA positions for further processing
  latitudes_filtered <- latitudes[!na_positions]
  longitudes_filtered <- longitudes[!na_positions]

  # Calculate UTM zone from median longitude
  median_lon <- median(longitudes_filtered, na.rm = TRUE)
  utm_zone <- floor((median_lon + 180) / 6) + 1

  hemisphere_north <- median(latitudes_filtered) >= 0
  base_epsg <- ifelse(hemisphere_north, 32600, 32700)
  utm_epsg <- paste0("epsg:", base_epsg + utm_zone)

  # Create a bounding box around the coordinates with a buffer
  bbox <- st_bbox(c(xmin = min(longitudes_filtered) - 1, xmax = max(longitudes_filtered) + 1,
                    ymin = min(latitudes_filtered) - 1, ymax = max(latitudes_filtered) + 1),
                  crs = st_crs(crs))

  # Get land polygon
  if (is.null(shape)) {
    url <- "https://naturalearth.s3.amazonaws.com/10m_physical/ne_10m_land.zip"
    exdir <- file.path(tempdir(), "ifcb_is_near_land")
    if (!dir.exists(exdir)) {
      dir.create(exdir, recursive = TRUE)
    }
    temp_zip <- file.path(exdir, "ne_10m_land.zip")

    if (!file.exists(temp_zip)) {
      # Try downloading with error handling
      tryCatch({
        curl::curl_download(url, temp_zip)
      }, error = function(e) {
        stop("Could not download Natural Earth land data. Please manually download it from:\n",
             "https://www.naturalearthdata.com/", "\nThen provide the path to the `.shp` file (or a custom shape file) using the `shape` argument.")
      })
    }

    # Unzip into the temp directory
    unzip(temp_zip, exdir = exdir)

    # Read the shapefile (assumes only one .shp file)
    shp_path <- list.files(exdir, pattern = "\\.shp$", full.names = TRUE)[1]
    land <- st_read(shp_path, quiet = TRUE)
  } else {
    land <- st_read(shape, quiet = TRUE)
    land <- st_transform(land, crs = crs)
  }

  # Check geometry type
  geom_type <- unique(st_geometry_type(land))

  # Optionally remove small islands based on area threshold
  if (!is.null(shape) && remove_small_islands && any(st_geometry_type(land) %in% c("POLYGON", "MULTIPOLYGON"))) {
    land$area <- st_area(land)

    small_islands <- which(as.numeric(land$area) < small_island_threshold)
    land <- land[-small_islands, ]

    # Remove the 'area' attribute
    land$area <- NULL
  }

  # Filter land data to include only the region within the bounding box
  land <- suppressWarnings(st_intersection(land, st_as_sfc(bbox)))

  # Cleanup and transform land data
  land <- land %>% st_union() %>% st_make_valid() %>% st_wrap_dateline()
  land_utm <- st_transform(land, crs = utm_epsg)

  # Create a buffered shape around the coastline in meters (specified distance)
  l_buffer <- st_buffer(land_utm, dist = distance)

  # Apply st_wrap_dateline only if the CRS is geographic
  if (st_crs(l_buffer)$epsg == crs) {
    l_buffer <- l_buffer %>% st_wrap_dateline()
  }

  # Transform the buffered coastline and land data back to the original CRS
  l_buffer <- st_transform(l_buffer, crs = crs)

  # Create sf object for positions
  positions_sf <- st_as_sf(data.frame(lon = longitudes_filtered, lat = latitudes_filtered),
                           coords = c("lon", "lat"), crs = st_crs(crs))

  # Check which positions intersect with the buffer and land
  near_land <- st_intersects(positions_sf, l_buffer)

  # Extract logical vectors indicating whether each position is near land or on land
  near_land_logical <- lengths(near_land) > 0

  # Assign results back to the appropriate positions in the result vector
  result[!na_positions] <- near_land_logical

  # Optional plotting
  if (plot) {
    positions_sf$near_land <- near_land_logical

    p <- ggplot() +
      geom_sf(data = land, fill = "gray80", color = "black", alpha = 0.5) +
      geom_sf(data = l_buffer, fill = "skyblue", color = NA, alpha = 0.3) +
      geom_sf(data = positions_sf, aes(color = near_land), size = 2) +
      scale_color_manual(values = c("TRUE" = "red", "FALSE" = "green")) +
      coord_sf(crs = crs) +
      labs(title = paste("Points Inside Land Buffer:", distance, "m"),
           color = "Near Land") +
      theme_minimal()

    return(p)
  }

  # Return the logical vector indicating near land with NAs for original NA positions
  return(result)
}
