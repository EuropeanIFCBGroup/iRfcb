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
# \donttest{
  bins <- ifcb_list_dashboard_bins("https://ifcb-data.whoi.edu/")
#> Fetching bin list from: https://ifcb-data.whoi.edu/api/list_bins
#> Successfully retrieved 793033 bins.
  head(bins)
#> # A tibble: 6 × 3
#>   pid                   sample_time          skip 
#>   <chr>                 <chr>                <lgl>
#> 1 IFCB1_2006_157_181359 2006-06-06T18:13:59Z TRUE 
#> 2 IFCB1_2006_157_183432 2006-06-06T18:34:32Z TRUE 
#> 3 IFCB1_2006_157_185616 2006-06-06T18:56:16Z TRUE 
#> 4 IFCB1_2006_157_191801 2006-06-06T19:18:01Z TRUE 
#> 5 IFCB1_2006_157_200140 2006-06-06T20:01:40Z TRUE 
#> 6 IFCB1_2006_157_202314 2006-06-06T20:23:14Z TRUE 
# }
```
