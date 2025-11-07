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
if (FALSE) { # \dontrun{
  # Download all metadata
  metadata_all <- ifcb_download_dashboard_metadata("https://ifcb-data.whoi.edu/")

  # Download metadata for a specific dataset
  metadata_svea <- ifcb_download_dashboard_metadata("https://ifcb-data.whoi.edu/", "mvco")
} # }
```
