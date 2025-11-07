# Retrieve Ferrybox Data for Specified Timestamps

This internal SMHI function reads `.txt` files from a specified folder
containing Ferrybox data, filters them based on a specified ship name
(default is "SveaFB" for R/V Svea), and extracts data (including GPS
coordinates) for timestamps (rounded to the nearest minute) falling
within the date ranges defined in the file names.

## Usage

``` r
ifcb_get_ferrybox_data(
  timestamps,
  ferrybox_folder,
  parameters = c("8002", "8003"),
  ship = "SveaFB",
  latitude_param = "8002",
  longitude_param = "8003"
)
```

## Arguments

- timestamps:

  A vector of POSIXct timestamps for which GPS coordinates and
  associated parameter data are to be retrieved.

- ferrybox_folder:

  A string representing the path to the folder containing Ferrybox
  `.txt` files.

- parameters:

  A character vector specifying the parameters to extract from the
  Ferrybox data. Defaults to `c("8002", "8003")`.

- ship:

  A string representing the name of the ship to filter Ferrybox files.
  The default is "SveaFB".

- latitude_param:

  A string specifying the header name for the latitude column in the
  Ferrybox data. Default is "8002".

- longitude_param:

  A string specifying the header name for the longitude column in the
  Ferrybox data. Default is "8003".

## Value

A data frame containing the input timestamps and corresponding data for
the specified parameters. Columns include 'timestamp', 'gpsLatitude',
'gpsLongitude' (if applicable), and the specified parameters.

## Details

The function extracts data from files whose names match the specified
ship and fall within the date ranges defined in the file names. The
columns corresponding to `latitude_param` and `longitude_param` will be
renamed to `gpsLatitude` and `gpsLongitude`, respectively, if they are
present in the `parameters` argument.

The function also handles cases where the exact timestamp is missing by
attempting to interpolate the data using floor and ceiling rounding
methods. The final output will ensure that all specified parameters are
numeric.

## Examples

``` r
if (FALSE) { # \dontrun{
ferrybox_folder <- "/path/to/ferrybox/data"
timestamps <- as.POSIXct(c("2016-08-10 10:47:34 UTC",
                           "2016-08-10 11:12:21 UTC",
                           "2016-08-10 11:35:59 UTC"))

result <- ifcb_get_ferrybox_data(timestamps, ferrybox_folder)
print(result)
} # }
```
