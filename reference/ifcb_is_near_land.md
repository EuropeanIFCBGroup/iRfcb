# Determine if Positions are Near Land

Determines whether given positions are near land based on a land polygon
shape file. The Natural Earth 1:10m land vectors are included as a
default shapefile in `iRfcb`.

## Usage

``` r
ifcb_is_near_land(
  latitudes,
  longitudes,
  distance = 500,
  shape = NULL,
  source = "ne",
  crs = 4326,
  remove_small_islands = TRUE,
  small_island_threshold = 2e+06,
  plot = FALSE,
  utm_zone = deprecated()
)
```

## Arguments

- latitudes:

  Numeric vector of latitudes for positions.

- longitudes:

  Numeric vector of longitudes for positions. Must be the same length as
  `latitudes`.

- distance:

  Buffer distance (in meters) from the coastline to consider "near
  land." Default is 500 meters.

- shape:

  Optional path to a shapefile (`.shp`) containing coastline data. If
  provided, this file will be used instead of the default Natural Earth
  1:10m land vectors. A high-resolution shapefile can improve the
  accuracy of buffer distance calculations. Alternatively, you can
  retrieve a more detailed European coastline automatically by setting
  the `source` argument to `"eea"`.

- source:

  Character string indicating which default coastline source to use when
  `shape = NULL`. Options are `"ne"` (Natural Earth, default) and
  `"eea"` (European Environment Agency). Ignored if `shape` is provided.

- crs:

  Coordinate reference system (CRS) to use for input and output. Default
  is EPSG code 4326 (WGS84).

- remove_small_islands:

  Logical indicating whether to remove small islands from the coastline.
  Useful in archipelagos. Default is `TRUE`.

- small_island_threshold:

  Area threshold in square meters below which islands will be considered
  small and removed, if remove_small_islands is set to `TRUE`. Default
  is 2 square km.

- plot:

  A boolean indicating whether to plot the points, land polygon and
  buffer. Default is `FALSE`.

- utm_zone:

  **\[deprecated\]** This argument is deprecated. UTM zones are now
  determined automatically based on the longitude of the input
  positions.

## Value

If `plot = FALSE` (default), a logical vector is returned indicating
whether each position is near land or not, with `NA` for positions where
coordinates are missing. If `plot = TRUE`, a `ggplot` object is returned
showing the land polygon, buffer area, and position points colored by
their proximity to land.

## Details

This function calculates a buffered area around the coastline using a
polygon shapefile and determines if each input position intersects with
this buffer or the landmass itself. By default, it uses the Natural
Earth 1:10m land vector dataset.

The EEA shapefile is downloaded from
<https://www.eea.europa.eu/data-and-maps/data/eea-coastline-for-analysis-2/gis-data/eea-coastline-polygon>
when `source = "eea"`.

## Examples

``` r
if (FALSE) { # \dontrun{
# Define coordinates
latitudes <- c(62.500353, 58.964498, 57.638725, 56.575338)
longitudes <- c(17.845993, 20.394418, 18.284523, 16.227174)

# Call the function
near_land <- ifcb_is_near_land(latitudes, longitudes, distance = 300, crs = 4326)

# Print the result
print(near_land)
} # }
```
