# Download and Extract WHOI-Plankton Data

This function downloads WHOI-Plankton annotated plankton images (Sosik
et al. 2015) for specified years from
<https://hdl.handle.net/1912/7341>. The extracted `.png` data are saved
in the specified destination folder.

## Usage

``` r
ifcb_download_whoi_plankton(
  years,
  dest_folder,
  extract_images = TRUE,
  max_retries = 10,
  quiet = FALSE
)
```

## Arguments

- years:

  A vector of years (numeric or character) indicating which datasets to
  download. The available years are currently 2006 to 2014.

- dest_folder:

  A string specifying the destination folder where the files will be
  extracted.

- extract_images:

  Logical. If `TRUE`, extracts `.png` images from the downloaded
  archives and removes the `.zip` files. If `FALSE`, only downloads the
  archives without extracting images. Default is `TRUE`.

- max_retries:

  An integer specifying the maximum number of attempts to retrieve data.
  Default is 10.

- quiet:

  Logical. If TRUE, suppresses messages about the progress and
  completion of the download process. Default is FALSE.

## Value

If `extract_images = FALSE`, returns a data frame containing metadata of
downloaded image files. Otherwise, no return value; files are downloaded
and extracted to `dest_folder`.

## References

Sosik, H. M., Peacock, E. E. and Brownlee E. F. (2015), Annotated
Plankton Images - Data Set for Developing and Evaluating Classification
Methods. [doi:10.1575/1912/7341](https://doi.org/10.1575/1912/7341)

## Examples

``` r
if (FALSE) { # \dontrun{
# Download and extract images for 2006 and 2007 in the data folder
ifcb_download_whoi_plankton(c(2006, 2007),
                            "data",
                            extract_images = TRUE)
} # }
```
