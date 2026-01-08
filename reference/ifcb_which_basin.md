# Determine if Points are in a Specified Sea Basin

This function identifies which sub-basin a set of latitude and longitude
points belong to, using a user-specified or default shapefile. The
default shapefile includes the Baltic Sea, Kattegat, and Skagerrak
basins and is included in the `iRfcb` package.

## Usage

``` r
ifcb_which_basin(latitudes, longitudes, plot = FALSE, shape_file = NULL)
```

## Arguments

- latitudes:

  A numeric vector of latitude points.

- longitudes:

  A numeric vector of longitude points.

- plot:

  A boolean indicating whether to plot the points along with the sea
  basins. Default is FALSE.

- shape_file:

  The absolute path to a custom polygon shapefile in WGS84 (EPSG:4326)
  that represents the sea basin. Defaults to the Baltic Sea, Kattegat,
  and Skagerrak basins included in the `iRfcb` package.

## Value

A vector indicating the basin each point belongs to, or a ggplot object
if `plot = TRUE`.

## Details

This function reads a pre-packaged shapefile of the Baltic Sea,
Kattegat, and Skagerrak basins from the `iRfcb` package by default, or a
user-supplied shapefile if provided. The shapefiles originate from SHARK
(https://shark.smhi.se/en/). It sets the CRS, transforms the CRS to
WGS84 (EPSG:4326) if necessary, and checks if the given points fall
within the specified sea basin. Optionally, it plots the points and the
sea basin polygons together.

## Examples

``` r
# Define example latitude and longitude vectors
latitudes <- c(55.337, 54.729, 56.311, 57.975)
longitudes <- c(12.674, 14.643, 12.237, 10.637)

# Check in which Baltic sea basin the points are in
points_in_the_baltic <- ifcb_which_basin(latitudes, longitudes)
print(points_in_the_baltic)
#> [1] "13 - Arkona Basin"   "12 - Bornholm Basin" "16 - Kattegat"      
#> [4] "17 - Skagerrak"     

# Plot the points and the basins
ifcb_which_basin(latitudes, longitudes, plot = TRUE)

```
