# Download and Prepare WHOI-Plankton Data

This function downloads manually annotated images from the WHOI-Plankton
dataset (Sosik et al. 2015) and generates manual classification files in
`.mat` format that can be used to train an image classifier using the
`ifcb-analysis` MATLAB package (Sosik and Olson 2007).

## Usage

``` r
ifcb_prepare_whoi_plankton(
  years,
  png_folder,
  raw_folder,
  manual_folder,
  class2use_file,
  skip_classes = NULL,
  include_classes = NULL,
  dashboard_url = "https://ifcb-data.whoi.edu/mvco/",
  extract_images = FALSE,
  download_blobs = FALSE,
  blobs_folder = NULL,
  download_features = FALSE,
  features_folder = NULL,
  parallel_downloads = 5,
  sleep_time = 2,
  multi_timeout = 120,
  convert_filenames = TRUE,
  convert_adc = TRUE,
  quiet = FALSE
)
```

## Arguments

- years:

  Character vector. Years to download and process. For available years,
  see <https://hdl.handle.net/1912/7341> or
  [`ifcb_download_whoi_plankton`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_whoi_plankton.md).

- png_folder:

  Character. Directory where `.png` images will be stored.

- raw_folder:

  Character. Directory where raw files (`.adc`, `.hdr`, `.roi`) will be
  stored.

- manual_folder:

  Character. Directory where manual classification files (`.mat`) will
  be stored.

- class2use_file:

  Character. File path to `.mat` file to store the list of available
  classes.

- skip_classes:

  Character vector. Classes to be excluded during processing. For
  example images, refer to <https://whoigit.github.io/whoi-plankton/>.

- include_classes:

  Character vector. If provided, only these classes will be included
  during processing. Applied before `skip_classes`. For example images,
  refer to <https://whoigit.github.io/whoi-plankton/>.

- dashboard_url:

  Character. URL for the IFCB dashboard data source (default:
  "https://ifcb-data.whoi.edu/mvco/").

- extract_images:

  Logical. If `TRUE`, extracts `.png` images from the downloaded
  archives and removes the `.zip` files. If `FALSE`, only downloads the
  archives without extracting images. Default is `FALSE`.

- download_blobs:

  Logical. Whether to download blob files (default: FALSE).

- blobs_folder:

  Character. Directory where blob files will be stored (required if
  `download_blobs = TRUE`).

- download_features:

  Logical. Whether to download feature files (default: FALSE).

- features_folder:

  Character. Directory where feature files will be stored (required if
  `download_features = TRUE`).

- parallel_downloads:

  Integer. Number of parallel IFCB Dashboard downloads (default: 5).

- sleep_time:

  Numeric. Seconds to wait between download requests (default: 2).

- multi_timeout:

  Numeric. Timeout for multiple requests in seconds (default: 120).

- convert_filenames:

  Logical. If `TRUE` (default), converts filenames of the old format
  `"IFCBxxx_YYYY_DDD_HHMMSS"` to the new format
  (`DYYYYMMDDTHHMMSS_IFCBXXX`). **\[experimental\]**

- convert_adc:

  Logical. If `TRUE` (default), adjusts `.adc` files from older IFCB
  instruments (IFCB1–6, with filenames in the format
  `"IFCBxxx_YYYY_DDD_HHMMSS"`) by inserting four empty columns after
  column 7 to match the newer format. **\[experimental\]**

- quiet:

  Logical. Suppress messages if TRUE (default: FALSE).

## Value

This function does not return a value but downloads, processes, and
stores IFCB data.

## Details

This function requires a python interpreter to be installed. The
required python packages can be installed in a virtual environment using
[`ifcb_py_install()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md).

This is a wrapper function for the
[`ifcb_download_whoi_plankton`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_whoi_plankton.md),
[`ifcb_download_dashboard_data`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_dashboard_data.md)
and
[`ifcb_create_manual_file`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_manual_file.md)
functions and used for downloading, processing, and converting IFCB
data. Please note that this function downloads and extracts large
amounts of data, which can take considerable time.

The training data prepared from this function can be merged with an
existing training dataset using the
[`ifcb_merge_manual`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_merge_manual.md)
function.

Classes included in the training dataset can be controlled using the
`include_classes` and `skip_classes` arguments. If `include_classes` is
provided, only the specified classes will be processed and included in
the output. The `skip_classes` argument can be used to explicitly
exclude one or more classes. If both arguments are supplied,
`include_classes` is applied first and `skip_classes` is applied
afterward.

To exclude individual images rather than entire classes, set
`extract_images = TRUE`, manually delete specific `.png` files from the
`png_folder`, and rerun `ifcb_prepare_whoi_plankton`.

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

Sosik, H. M., Peacock, E. E. and Brownlee E. F. (2015), Annotated
Plankton Images - Data Set for Developing and Evaluating Classification
Methods. [doi:10.1575/1912/7341](https://doi.org/10.1575/1912/7341)

## See also

<https://hdl.handle.net/1912/7341>,
<https://whoigit.github.io/whoi-plankton/>
[`ifcb_merge_manual`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_merge_manual.md)
[`ifcb_download_whoi_plankton`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_whoi_plankton.md)
[`ifcb_download_dashboard_data`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_dashboard_data.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Download and prepare WHOI-Plankton for the years 2013 and 2014
ifcb_prepare_whoi_plankton(
  years = c("2013", "2014"),
  png_folder = "whoi_plankton/png",
  raw_folder = "whoi_plankton/raw",
  manual_folder = "whoi_plankton/manual",
  class2use_file = "whoi_plankton/config/class2use_whoiplankton.mat"
)
} # }
```
