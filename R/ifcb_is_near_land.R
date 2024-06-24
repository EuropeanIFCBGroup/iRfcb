#' Determine if Positions are Near Land
#'
#' Determines whether given positions are near land based on a buffered coastline.
#'
#' @param latitudes Numeric vector of latitudes for positions.
#' @param longitudes Numeric vector of longitudes for positions.
#' @param distance Buffer distance in meters around the coastline. Default is 100 m.
#' @param shape Optional path to a shapefile containing coastline data. If provided,
#'   the function will use this shapefile instead of reading rnaturalearth 1:10m vectors.
#'   A more detailed shapefile allows for a smaller buffer distance.
#'   Detailed European coastline can be downloaded as polygons from EEA at
#'   \url{https://www.eea.europa.eu/data-and-maps/data/eea-coastline-for-analysis-2/gis-data/eea-coastline-polygon}
#' @param crs Coordinate reference system (CRS) to use for positions and output.
#'   Default is EPSG code 4326 (WGS84).
#' @param utm_zone UTM zone for buffering the coastline. Default is 33 (between 12°E and 18°E, northern hemisphere).
#' @param remove_small_islands Logical indicating whether to remove small islands from
#'   the coastline. Default is TRUE.
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
#' @importFrom sf st_bbox st_crs st_as_sf st_transform st_intersects st_wrap_dateline st_as_sfc st_intersection st_make_valid st_union st_area st_geometry_type st_read
#' @importFrom terra vect buffer
#' @importFrom dplyr %>%
#' @importFrom zip unzip
#' @export
ifcb_is_near_land <- function(latitudes,
                              longitudes,
                              distance = 100,
                              shape = NULL,
                              crs = 4326,
                              utm_zone = 33,
                              remove_small_islands = TRUE,
                              small_island_threshold = 2000000) {

  utm_epsg <- paste0("epsg:", 32600 + utm_zone)

  # Create a bounding box around the coordinates with a buffer
  bbox <- st_bbox(c(xmin = min(longitudes) - 1, xmax = max(longitudes) + 1,
                    ymin = min(latitudes) - 1, ymax = max(latitudes) + 1),
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
  if (remove_small_islands && any(st_geometry_type(land) %in% c("POLYGON", "MULTIPOLYGON"))) {
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
  l_buffer <- terra::vect(land_utm)
  terra::crs(l_buffer) <- utm_epsg
  l_buffer <- terra::buffer(l_buffer, width = distance) %>% st_as_sf() %>% st_wrap_dateline()

  # Transform the buffered coastline and land data back to the original CRS
  l_buffer <- st_transform(l_buffer, crs = crs)

  # Create sf object for positions
  positions_sf <- st_as_sf(data.frame(lon = longitudes, lat = latitudes),
                           coords = c("lon", "lat"), crs = st_crs(crs))

  # Check which positions intersect with the buffer and land
  near_land <- st_intersects(positions_sf, l_buffer)

  # Extract logical vectors indicating whether each position is near land or on land
  near_land_logical <- lengths(near_land) > 0

  # Return the logical vector indicating near land
  return(near_land_logical)
}
