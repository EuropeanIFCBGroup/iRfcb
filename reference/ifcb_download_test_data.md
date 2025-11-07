# Download Test IFCB Data

This function downloads a zip archive containing MATLAB files from the
`iRfcb` dataset available in the SMHI IFCB Plankton Image Reference
Library (Torstensson et al. 2024), unzips them into the specified folder
and extracts png images. These data can be used, for instance, for
testing `iRfcb` and for creating the tutorial vignette using
[`vignette("a-general-tutorial", package = "iRfcb")`](https://europeanifcbgroup.github.io/iRfcb/articles/a-general-tutorial.md)

## Usage

``` r
ifcb_download_test_data(
  dest_dir,
  figshare_article = "48158716",
  expected_checksum = NULL,
  max_retries = 5,
  sleep_time = 10,
  keep_zip = FALSE,
  verbose = TRUE
)
```

## Arguments

- dest_dir:

  The destination directory where the files will be unzipped.

- figshare_article:

  The file article number at the SciLifeLab Figshare data repository. By
  default, the `iRfcb` test dataset (48158716) from Torstensson et
  al. (2024) is used.

- expected_checksum:

  Optional. The expected MD5 checksum of the downloaded zip file. If not
  provided, it is automatically looked up from an internal table based
  on `figshare_article`.

- max_retries:

  The maximum number of retry attempts in case of download failure.
  Default is 5.

- sleep_time:

  The sleep time between download attempts, in seconds. Default is 10.

- keep_zip:

  A logical indicating whether to keep the downloaded zip archive after
  its download. Default is FALSE.

- verbose:

  A logical indicating whether to print progress messages. Default is
  TRUE.

## Value

No return value. This function is called for its side effect of
downloading, extracting, and organizing IFCB test data.

## References

Torstensson, Anders; Skjevik, Ann-Turi; Mohlin, Malin; Karlberg, Maria;
Karlson, Bengt (2024). SMHI IFCB Plankton Image Reference Library.
Version 3. SciLifeLab. Dataset.
[doi:10.17044/scilifelab.25883455.v3](https://doi.org/10.17044/scilifelab.25883455.v3)

## Examples

``` r
if (FALSE) { # \dontrun{
# Download and unzip IFCB test data into the "data" directory
ifcb_download_test_data("data")
} # }
```
