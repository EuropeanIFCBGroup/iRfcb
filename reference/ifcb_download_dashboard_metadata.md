# Download metadata from the IFCB Dashboard API

Download metadata from the IFCB Dashboard API

## Usage

``` r
ifcb_download_dashboard_metadata(base_url, dataset_name = NULL, quiet = FALSE)
```

## Arguments

- base_url:

  Character. Base URL to the IFCB Dashboard (e.g.
  "https://ifcb-data.whoi.edu/").

- dataset_name:

  Optional character. Dataset slug (e.g. "mvco") to retrieve metadata
  for a specific dataset. If NULL, all available metadata are
  downloaded.

- quiet:

  Logical. If TRUE, suppresses progress messages. Default is FALSE.

## Value

A data frame containing the exported metadata.

## See also

[`ifcb_download_dashboard_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_dashboard_data.md)
to download data from the IFCB Dashboard API.

[`ifcb_list_dashboard_bins()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_list_dashboard_bins.md)
to retrieve list of available bins from the IFCB Dashboard API.

## Examples

``` r
# \donttest{
  # Download metadata for a specific dataset
  metadata_mvco <- ifcb_download_dashboard_metadata("https://ifcb-data.whoi.edu/",
                                                    dataset_name = "mvco",
                                                    quiet = TRUE)

  # Print result as tibble
  dplyr::tibble(metadata_mvco)
#> # A tibble: 348,537 × 20
#>    dataset pid     sample_time  ifcb ml_analyzed latitude longitude depth cruise
#>    <chr>   <chr>   <chr>       <int>       <dbl>    <dbl>     <dbl> <dbl> <chr> 
#>  1 mvco    D20170… 2017-04-14…    10        2.57     41.3     -70.6     0 ""    
#>  2 mvco    D20170… 2017-04-14…    10        2.46     41.3     -70.6     0 ""    
#>  3 mvco    D20170… 2017-04-14…    10        2.70     41.3     -70.6     0 ""    
#>  4 mvco    D20170… 2017-04-14…    10        2.69     41.3     -70.6     0 ""    
#>  5 mvco    D20170… 2017-04-14…    10        2.75     41.3     -70.6     0 ""    
#>  6 mvco    D20170… 2017-04-14…    10        2.82     41.3     -70.6     0 ""    
#>  7 mvco    D20170… 2017-04-14…    10        2.63     41.3     -70.6     0 ""    
#>  8 mvco    D20170… 2017-04-14…    10        2.74     41.3     -70.6     0 ""    
#>  9 mvco    D20170… 2017-04-14…    10        2.85     41.3     -70.6     0 ""    
#> 10 mvco    D20170… 2017-04-14…    10        2.67     41.3     -70.6     0 ""    
#> # ℹ 348,527 more rows
#> # ℹ 11 more variables: cast <lgl>, niskin <lgl>, sample_type <chr>,
#> #   n_images <int>, tag1 <chr>, tag2 <chr>, tag3 <chr>, tag4 <chr>,
#> #   comment_summary <chr>, trigger_selection <int>, skip <int>
# }
```
