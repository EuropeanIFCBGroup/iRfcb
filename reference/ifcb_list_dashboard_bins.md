# Download bin list from the IFCB Dashboard API

**\[deprecated\]**

The `api/list_bins` endpoint was removed from the upstream IFCB
Dashboard
([WHOIGit/ifcbdb@8c5839f1](https://github.com/WHOIGit/ifcbdb/commit/8c5839f1),
2026-03-08), so this function no longer works against the WHOI dashboard
and other deployments tracking upstream. Use
[`ifcb_download_dashboard_metadata()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_dashboard_metadata.md)
instead, which retrieves the same per-bin information from the
still-supported `api/export_metadata` endpoint.

## Usage

``` r
ifcb_list_dashboard_bins(base_url, dataset_name = NULL, quiet = FALSE)
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

A data frame containing the bin list returned by the API.

## See also

[`ifcb_download_dashboard_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_dashboard_data.md)
to download data from the IFCB Dashboard API.

[`ifcb_download_dashboard_metadata()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_dashboard_metadata.md)
to retrieve metadata from the IFCB Dashboard API.

## Examples

``` r
if (FALSE) { # \dontrun{
  # Deprecated: the upstream IFCB Dashboard removed `api/list_bins` on 2026-03-08.
  bins <- ifcb_list_dashboard_bins("https://ifcb-data.whoi.edu/",
                                   dataset_name = "mvco")
  head(bins)
} # }
```
