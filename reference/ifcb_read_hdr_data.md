# Read Data from IFCB HDR Files

This function reads all IFCB instrument settings information files
(.hdr) from a specified directory.

## Usage

``` r
ifcb_read_hdr_data(
  hdr_files,
  gps_only = FALSE,
  verbose = TRUE,
  hdr_folder = deprecated()
)
```

## Arguments

- hdr_files:

  A character string or character vector specifying the path(s) to
  `.hdr` files, or a single folder path.

- gps_only:

  A logical value indicating whether to include only GPS information
  (latitude and longitude). Default is FALSE.

- verbose:

  A logical value indicating whether to print progress messages. Default
  is TRUE.

- hdr_folder:

  **\[deprecated\]**

  Use `hdr_files` instead.

## Value

A data frame with sample names, GPS latitude, GPS longitude, and
timestamps. When `gps_only = TRUE`, only samples with GPS coordinates
are included.

## Examples

``` r
if (FALSE) { # \dontrun{
# Extract all HDR data
hdr_data <- ifcb_read_hdr_data("path/to/data")
print(hdr_data)

# Extract only GPS data
gps_data <- ifcb_read_hdr_data("path/to/data", gps_only = TRUE)
print(gps_data)
} # }
```
