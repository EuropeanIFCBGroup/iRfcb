# Download IFCB data files from an IFCB Dashboard

This function downloads specified IFCB data files from a given IFCB
Dashboard URL. It supports optional filename conversion and ADC file
adjustments from the old IFCB file format.

## Usage

``` r
ifcb_download_dashboard_data(
  dashboard_url,
  samples,
  file_types,
  dest_dir,
  convert_filenames = FALSE,
  convert_adc = FALSE,
  parallel_downloads = 5,
  sleep_time = 2,
  multi_timeout = 120,
  max_retries = 3,
  quiet = FALSE
)
```

## Arguments

- dashboard_url:

  Character. The base URL of the IFCB dashboard (e.g.,
  `"https://ifcb-data.whoi.edu"`). If no subpath (e.g., `/data/` or
  `/mvco/`) is included, `/data/` will be added automatically. For the
  "features" and "autoclass" `file_types`, the dataset name needs to be
  included in the url (e.g. `"https://ifcb-data.whoi.edu/mvco/"`).

- samples:

  Character vector. The IFCB sample identifiers (e.g.,
  `"IFCB1_2014_188_222013"` or `"D20220807T025424_IFCB010"`).

- file_types:

  Character vector. Specifies which file types to download. Allowed
  values: `"blobs"`, `"features"`, `"autoclass"`, `"roi"`, `"zip"`,
  `"hdr"`, `"adc"`.

- dest_dir:

  Character. The directory where downloaded files will be saved.

- convert_filenames:

  Logical. If `TRUE`, converts filenames of the old format
  `"IFCBxxx_YYYY_DDD_HHMMSS"` to the new format
  (`DYYYYMMDDTHHMMSS_IFCBXXX` or `IYYYYMMDDTHHMMSS_IFCBXXX`). Default is
  `FALSE`. **\[experimental\]**

- convert_adc:

  Logical. If `TRUE`, adjusts `.adc` files from older IFCB instruments
  (IFCB1–6, with filenames in the format `"IFCBxxx_YYYY_DDD_HHMMSS"`) by
  inserting four empty columns after column 7 to match the newer format.
  Default is `FALSE`. **\[experimental\]**

- parallel_downloads:

  Integer. The number of files to download in parallel per batch. This
  helps manage network load and system performance. Default is `5`.

- sleep_time:

  A numeric value indicating the number of seconds to wait between each
  batch of downloads. Default is `2`.

- multi_timeout:

  Numeric. The maximum time in seconds that the `curl` multi-download
  request will wait for a response before timing out. This helps prevent
  hanging downloads in case of slow or unresponsive servers. Default is
  `120` seconds.

- max_retries:

  An integer specifying the maximum number of attempts to retrieve data
  in case the server is unable to handle the request. Default is 3.

- quiet:

  Logical. If TRUE, suppresses messages about the progress and
  completion of the download process. Default is FALSE.

## Value

This function does not return a value. It performs the following
actions:

- Downloads the requested files into `dest_dir`.

- If `convert_adc = TRUE`, modifies ADC files in place by inserting four
  empty columns after column 7.

- Displays messages indicating the download status.

## Details

This function can download several files in parallel if the server
allows it. The download parameters can be adjusted using the
`parallel_downloads`, `sleep_time` and `multi_timeout` arguments.

If `convert_filenames = TRUE` **\[experimental\]**, filenames in the
`"IFCBxxx_YYYY_DDD_HHMMSS"` format (used by IFCB1-6) will be converted
to `IYYYYMMDDTHHMMSS_IFCBXXX`, ensuring compatibility with blob
extraction in `ifcb-analysis` (Sosik & Olson, 2007), which identified
the old `.adc` format by the first letter of the filename.

If `convert_adc = TRUE` **\[experimental\]** and
`convert_filenames = TRUE` **\[experimental\]**, the
`"IFCBxxx_YYYY_DDD_HHMMSS"` format will instead be converted to
`DYYYYMMDDTHHMMSS_IFCBXXX`. Additionally, `.adc` files will be modified
to include four empty columns (PMT-A peak, PMT-B peak, PMT-C peak, and
PMT-D peak), aligning them with the structure of modern `.adc` files for
full compatibility with `ifcb-analysis`.

## References

Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification
of phytoplankton sampled with imaging-in-flow cytometry. Limnol.
Oceanogr: Methods 5, 204–216.

## See also

[`ifcb_download_dashboard_metadata()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_dashboard_metadata.md)
to retrieve metadata from the IFCB Dashboard API.

[`ifcb_list_dashboard_bins()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_list_dashboard_bins.md)
to retrieve list of available bins from the IFCB Dashboard API.

## Examples

``` r
if (FALSE) { # \dontrun{
ifcb_download_dashboard_data(
  dashboard_url = "https://ifcb-data.whoi.edu/mvco/",
  samples = "IFCB1_2014_188_222013",
  file_types = c("blobs", "autoclass"),
  dest_dir = "data",
  convert_filenames = FALSE,
  convert_adc = FALSE
)
} # }
```
