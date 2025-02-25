#' Determine if Positions are Near Land
#'
#' Determines whether given positions are near land based on a coastline shape file.
#' The Natural Earth 1:10m land vectors are included as default shapefile in `iRfcb`.
#'
#' @param latitudes Numeric vector of latitudes for positions.
#' @param longitudes Numeric vector of longitudes for positions.
#' @param distance Buffer distance in meters around the coastline. Default is 500 m.
#' @param shape Optional path to a shapefile containing coastline data. If provided,
#'   the function will use this shapefile instead of the default Natural Earth 1:10m land vectors.
#'   Using a more detailed shapefile allows for a smaller buffer distance.
#'   For detailed European coastlines, download polygons from the EEA at
#'   \url{https://www.eea.europa.eu/data-and-maps/data/eea-coastline-for-analysis-2/gis-data/eea-coastline-polygon}.
#'   For more detailed world maps, download from Natural Earth at
#'   \url{https://www.naturalearthdata.com/downloads/10m-physical-vectors/}.
#' @param crs Coordinate reference system (CRS) to use for positions and output.
#'   Default is EPSG code 4326 (WGS84).
#' @param utm_zone UTM zone for buffering the coastline. Default is 33 (between 12°E and 18°E, northern hemisphere).
#' @param remove_small_islands Logical indicating whether to remove small islands from
#'   the coastline if a custom shapefile is provided. Default is TRUE.
#' @param small_island_threshold Area threshold in square meters below which islands
#'   will be considered small and removed, if remove_small_islands is set to TRUE. Default is 2 sqkm.
#'
#' @return Logical vector indicating whether each position is near land.
#'
#' @details
#' This function calculates a buffered area around the coastline and checks if
#' given positions (specified by longitudes and latitudes) are within this buffer
#' or intersect with land.
#'
#' @examples
#' # Define coordinates
#' latitudes <- c(62.500353, 58.964498, 57.638725, 56.575338)
#' longitudes <- c(17.845993, 20.394418, 18.284523, 16.227174)
#'
#' # Call the function
#' near_land <- ifcb_is_near_land(latitudes, longitudes, distance = 300, crs = 4326)
#'
#' # Print the result
#' print(near_land)
#'
#' @export
ifcb_is_near_land <- function(latitudes,
                              longitudes,
                              distance = 500,
                              shape = NULL,
                              crs = 4326,
                              utm_zone = 33,
                              remove_small_islands = TRUE,
                              small_island_threshold = 2000000) {

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

  utm_epsg <- paste0("epsg:", 32600 + utm_zone)

  # Create a bounding box around the coordinates with a buffer
  bbox <- st_bbox(c(xmin = min(longitudes_filtered) - 1, xmax = max(longitudes_filtered) + 1,
                    ymin = min(latitudes_filtered) - 1, ymax = max(latitudes_filtered) + 1),
                  crs = st_crs(crs))

  # Get coastline
  if (is.null(shape)) {
    # Directory to extract files
    exdir <- tempdir()  # Temporary directory

    # Extract the files
    unzip(system.file("exdata/ne_10m_land.zip", package = "iRfcb"), exdir = exdir)

    # Get coastline and land data within the bounding box
    land <- st_read(file.path(exdir, "ne_10m_land.shp"), quiet = TRUE)
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

  # Return the logical vector indicating near land with NAs for original NA positions
  return(result)
}
