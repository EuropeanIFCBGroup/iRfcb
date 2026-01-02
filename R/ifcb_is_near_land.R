#' Determine if Positions are Near Land
#'
#' Determines whether given positions are near land based on a land polygon shape file.
#' The Natural Earth 1:10m land vectors are included as a default shapefile in `iRfcb`.
#'
#' @param latitudes Numeric vector of latitudes for positions.
#' @param longitudes Numeric vector of longitudes for positions. Must be the same length as `latitudes`.
#' @param distance Buffer distance (in meters) from the coastline to consider "near land." Default is 500 meters.
#' @param shape Optional path to a shapefile (`.shp` or `.gpkg`) containing coastline data. If provided,
#'   this file will be used instead of the default Natural Earth 1:10m land vectors.
#'   A high-resolution shapefile can improve the accuracy of buffer distance calculations.
#'   Alternatively, you can retrieve a more detailed European coastline automatically by
#'   setting the `source` argument to `"eea"`.
#' @param source Character string indicating which default coastline source to use when `shape = NULL`.
#'   Options are `"ne"` (Natural Earth, default) and `"eea"` (European Environment Agency, 2017).
#'   Ignored if `shape` is provided.
#' @param crs Coordinate reference system (CRS) to use for input and output.
#'   Default is EPSG code 4326 (WGS84).
#' @param remove_small_islands Logical indicating whether to remove small islands from
#'   the coastline. Useful in archipelagos. Default is `TRUE`.
#' @param small_island_threshold Area threshold in square meters below which islands
#'   will be considered small and removed, if remove_small_islands is set to `TRUE`. Default is 2 square km.
#' @param plot A boolean indicating whether to plot the points, land polygon and buffer. Default is `FALSE`.
#' @param verbose A logical indicating whether to print progress messages. Default is TRUE.
#' @param utm_zone `r lifecycle::badge("deprecated")`
#'   This argument is deprecated. UTM zones are now determined automatically based on the longitude of the input positions.
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
#' By default, it uses the Natural Earth 1:10m land vector dataset.
#'
#' The EEA shapefile is downloaded when `source = "eea"` (European Environment Agency, 2017).
#' The downloaded file is cached within an R session.
#'
#' @examples
#' \donttest{
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
#' @references European Environment Agency (2017). EEA coastline for analysis (polygon) - version 3.0, March 2017. <https://sdi.eea.europa.eu/catalogue/geoss/api/records/9faa6ea1-372a-4826-a3c7-fb5b05e31c52>
#'
#' @export
ifcb_is_near_land <- function(latitudes,
                              longitudes,
                              distance = 500,
                              shape = NULL,
                              source = "ne",
                              crs = 4326,
                              remove_small_islands = TRUE,
                              small_island_threshold = 2000000,
                              plot = FALSE,
                              verbose = TRUE,
                              utm_zone = deprecated()) {

  stopifnot(length(latitudes) == length(longitudes))

  # Warn the user if utm_zone is used
  if (lifecycle::is_present(utm_zone)) {

    # Signal the deprecation to the user
    lifecycle::deprecate_warn("0.5.0", "iRfcb::ifcb_is_near_land(utm_zone = )",
                              details = "utm_zone is now calculated from the median longitude of the input coordinates.")
  }

  # Check for NAs in latitudes and longitudes
  na_positions <- is.na(latitudes) | is.na(longitudes)

  # Assign UTM zones
  utm_zones <- floor((longitudes + 180) / 6) + 1
  original_index <- seq_along(latitudes)

  # Create master result vector
  result <- rep(NA, length(latitudes))

  # If all positions are NA, return the result early
  if (all(na_positions)) {
    if (plot) {
      stop("All positions are NA. No plot can be generated.")
    }
    return(result)
  }

  # Load land shapefile if not provided
  if (is.null(shape)) {
    source <- match.arg(source, choices = c("ne", "eea"))  # Default source = "ne"
    exdir <- file.path(tempdir(), paste0("ifcb_is_near_land_", source))
    if (!dir.exists(exdir)) {
      dir.create(exdir, recursive = TRUE)
    }

    if (source == "ne") {
      # Extract the files
      unzip(system.file("exdata/ne_10m_land.zip", package = "iRfcb"), exdir = exdir)

      # Get coastline and land data within the bounding box
      shp_path <- list.files(exdir, pattern = "\\.shp$", full.names = TRUE)[1]
      land <- st_read(shp_path, quiet = TRUE)

    } else if (source == "eea") {

      eea_file <-file.path(exdir, "EEA_Coastline_2017.gpkg")

      if (!file.exists(eea_file)) {
        base <- "https://marine.discomap.eea.europa.eu/arcgis/rest/services/Marine/EEA_coastline_2017/MapServer/0"

        # get object IDs
        oid_url <- paste0(
          base,
          "/query?where=1=1&returnIdsOnly=true&f=json"
        )

        oids <- jsonlite::fromJSON(oid_url)$objectIds

        chunk_size <- 1000
        chunks <- split(oids, ceiling(seq_along(oids) / chunk_size))
        n_chunks <- length(chunks)

        # set up progress bar
        if (verbose && n_chunks > 0) {
          cat("Downloading EEA coastline data...\n")
          pb <- txtProgressBar(min = 0, max = n_chunks, style = 3)
        }

        coast_list <- vector("list", n_chunks)

        for (i in seq_along(chunks)) {

          if (verbose && n_chunks > 0) {
            setTxtProgressBar(pb, i)
          }

          query <- paste0(
            base,
            "/query?",
            "objectIds=", paste(chunks[[i]], collapse = ","),
            "&outFields=*",
            "&f=geojson"
          )

          coast_list[[i]] <- st_read(query, quiet = TRUE)
        }

        # close progress bar
        if (verbose && n_chunks > 0) {
          close(pb)
        }

        coast <- do.call(rbind, coast_list)

        st_write(coast, eea_file, quiet = TRUE, append = FALSE)
      }

      # unzip(temp_zip, exdir = exdir)
      shp_path <- list.files(exdir, pattern = "\\.gpkg$", full.names = TRUE)[1]

      # Read the shapefile
      land <- st_read(shp_path, quiet = TRUE)
      land <- st_transform(land, crs = crs)
    }
  } else {
    land <- st_read(shape, quiet = TRUE)
    land <- st_transform(land, crs = crs)
  }

  # Remove small islands if requested
  if (remove_small_islands && any(sf::st_geometry_type(land) %in% c("POLYGON", "MULTIPOLYGON"))) {
    land$area <- sf::st_area(land)
    land <- land[as.numeric(land$area) >= small_island_threshold, ]
    land$area <- NULL
  }

  # Filter out NA coordinates
  valid <- !is.na(latitudes) & !is.na(longitudes)
  coords <- data.frame(
    index = original_index[valid],
    lat = latitudes[valid],
    lon = longitudes[valid],
    utm_zone = utm_zones[valid]
  )

  # Process each UTM zone subset
  for (zone in unique(coords$utm_zone)) {
    subset <- coords[coords$utm_zone == zone, ]

    # Create a bounding box around the coordinates with a buffer
    bbox <- st_bbox(c(xmin = min(subset$lon) - 1, xmax = max(subset$lon) + 1,
                      ymin = min(subset$lat) - 1, ymax = max(subset$lat) + 1),
                    crs = st_crs(crs))

    # Filter land data to include only the region within the bounding box
    land_crop <- suppressWarnings(st_intersection(land, st_as_sfc(bbox)))

    # Cleanup and transform land data
    land_crop <- land_crop %>% st_union() %>% st_make_valid() %>% st_wrap_dateline()

    # Create sf points
    points_wgs <- sf::st_as_sf(subset, coords = c("lon", "lat"), crs = crs)

    epsg_code <- if (mean(subset$lat) >= 0) {
      32600 + zone  # Northern Hemisphere
    } else {
      32700 + zone  # Southern Hemisphere
    }

    utm_epsg <- paste0("epsg:", epsg_code)

    # Transform land and points to UTM
    points_utm <- sf::st_transform(points_wgs, crs = epsg_code)
    land_utm <- st_transform(land_crop, crs = utm_epsg)

    # Create a buffered shape around the coastline in meters (specified distance)
    l_buffer <- st_buffer(land_utm, dist = distance)

    # Apply st_wrap_dateline only if the CRS is geographic
    if (st_crs(l_buffer)$epsg == crs) {
      l_buffer <- l_buffer %>% st_wrap_dateline()
    }

    # Transform the buffered coastline and land data back to the original CRS
    l_buffer <- st_transform(l_buffer, crs = crs)

    # Create sf object for positions
    positions_sf <- st_as_sf(data.frame(lon = subset$lon, lat = subset$lat),
                             coords = c("lon", "lat"), crs = st_crs(crs))

    # Check which positions intersect with the buffer and land
    near_land <- st_intersects(positions_sf, l_buffer)

    # Extract logical vectors indicating whether each position is near land or on land
    near_land_logical <- lengths(near_land) > 0

    # Assign results back to the appropriate positions in the result vector
    result[subset$index] <- near_land_logical
  }

  # Optional plotting
  if (plot) {
    positions_sf <- st_as_sf(data.frame(lon = coords$lon, lat = coords$lat,
                                        near_land = result[!is.na(result)]),
                             coords = c("lon", "lat"), crs = st_crs(crs))

    p <- ggplot() +
      geom_sf(data = land, fill = "gray80", color = "black", alpha = 0.5) +
      geom_sf(data = positions_sf, aes(color = near_land), size = 2) +
      scale_color_manual(values = c("TRUE" = "red", "FALSE" = "green")) +
      xlim(c(min(coords$lon) - .1, max(coords$lon) + .1)) +
      ylim(c(min(coords$lat) - .1, max(coords$lat) + .1)) +
      coord_sf(crs = crs) +
      labs(title = paste("Buffer Distance:", distance, "m"),
           color = "Near Land") +
      theme_minimal() +
      # Set white background and ensure plot background is white
      theme(
        panel.background = element_rect(fill = "white", color = NA),
        plot.background = element_rect(fill = "white", color = NA)
      )

    return(p)
  }

  result
}
