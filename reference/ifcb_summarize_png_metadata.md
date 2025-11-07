# Summarize PNG Image Metadata

This function processes IFCB data by reading images, matching them to
the corresponding header and feature files, and joining them into a
single dataframe. This function may be useful when preparing metadata
files for an EcoTaxa submission.

## Usage

``` r
ifcb_summarize_png_metadata(
  png_folder,
  feature_folder = NULL,
  feature_version = NULL,
  hdr_folder = NULL
)
```

## Arguments

- png_folder:

  Character. The file path to the folder containing the PNG images.

- feature_folder:

  Character. The file path to the folder containing the feature files
  (optional).

- feature_version:

  Optional numeric or character version to filter feature files by (e.g.
  2 for "\_v2"). Default is NULL (no filtering).

- hdr_folder:

  Character. The file path to the folder containing the header files
  (optional).

## Value

A dataframe that joins image data, header data, and feature data based
on the sample and roi number.

## Examples

``` r
if (FALSE) { # \dontrun{
png_folder <- "path/to/pngs"
feature_folder <- "path/to/features"
hdr_folder <- "path/to/hdr_data"
result_df <- ifcb_summarize_png_metadata(png_folder, feature_folder, hdr_folder)
} # }
```
