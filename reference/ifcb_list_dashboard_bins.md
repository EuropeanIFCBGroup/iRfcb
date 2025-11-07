# Download bin list from the IFCB Dashboard API

Download bin list from the IFCB Dashboard API

## Usage

``` r
ifcb_list_dashboard_bins(base_url, quiet = FALSE)
```

## Arguments

- base_url:

  Character. Base URL to the IFCB Dashboard (e.g.
  "https://ifcb-data.whoi.edu/").

- quiet:

  Logical. If TRUE, suppresses progress messages. Default is FALSE.

## Value

A data frame containing the bin list returned by the API.

## See also

[`ifcb_download_dashboard_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_dashboard_data.md)
to download data from the IFCB Dashboard API.

[`ifcb_download_dashboard_metadata()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_dashboard_metadata.md)
to retrieve metadata from the IFCB Dashboard API.

## Examples

``` r
if (FALSE) { # \dontrun{
  bins <- ifcb_list_dashboard_bins("https://ifcb-data.whoi.edu/")
  head(bins)
} # }
```
