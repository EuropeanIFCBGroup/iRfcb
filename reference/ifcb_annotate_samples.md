# Create Manual Classification MAT Files from PNG Subfolders

This function creates manual classification `.mat` files compatible with
the code in the `ifcb-analysis` MATLAB repository (Sosik and Olson 2007)
by mapping ROIs to class IDs based on user-provided PNG images
(organized into subfolders named after classes) and a `class2use` MAT
file.

## Usage

``` r
ifcb_annotate_samples(
  png_folder,
  adc_folder,
  class2use_file,
  output_folder,
  sample_names = NULL,
  unclassified_id = 1,
  remove_trailing_numbers = TRUE,
  do_compression = TRUE
)
```

## Arguments

- png_folder:

  Directory containing PNG images organized into subfolders named after
  classes. Each PNG file represents a single ROI extracted from an IFCB
  sample and must follow the standard IFCB naming convention (for
  example, `"D20220712T210855_IFCB134_00042.png"`), which is used to map
  the image to the corresponding ROI index in the ADC file.

- adc_folder:

  Directory containing ADC files for the samples.

- class2use_file:

  Path to a `class2use` MAT file. This file should contain the vector of
  classes used for matching PNG annotations to class IDs.

- output_folder:

  Directory where the resulting MAT files will be written. If the folder
  does not exist, it will be created automatically.

- sample_names:

  Optional character vector of IFCB sample names (e.g.,
  `"D20220712T210855_IFCB134"`). If `NULL` (default), all samples
  detected from the PNG filenames in `png_folder` will be processed.
  Each sample must have a corresponding ADC file in `adc_folder`.

- unclassified_id:

  An integer specifying the class ID to use for unclassified regions of
  interest (ROIs) when creating new manual `.mat` files. Default is `1`.

- remove_trailing_numbers:

  Logical. If TRUE (default), trailing numeric suffixes are removed from
  PNG subfolder names before matching them to entries in `class2use`
  (for example, `"Skeletonema_036"` becomes `"Skeletonema"`). This is
  useful when class folders include numeric identifiers that are not
  part of the class names in `class2use`.

- do_compression:

  A logical value indicating whether to compress the `.mat` file.
  Default is TRUE.

## Value

Invisibly returns `TRUE` on successful completion.

## Details

Python must be installed to use this function. The required python
packages can be installed in a virtual environment using
[`ifcb_py_install()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md).

Each sample should have ADC files in `adc_folder` and corresponding PNG
images stored in subfolders under `png_folder`, where each subfolder is
named after a class (e.g., `Skeletonema`, `Dinophysis_acuminata`,
`unclassified`). The function automatically maps PNG filenames to ROI
indices, assigns class IDs based on `class2use`, and writes the
resulting MAT file in `output_folder`.

- The function reads all PNG images in subfolders of `png_folder`,
  extracts class names from folder names, and converts PNG filenames to
  ROI indices using
  [`ifcb_convert_filenames()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_convert_filenames.md).

- Class IDs are assigned using
  [`match()`](https://rdrr.io/r/base/match.html) against `class2use`. If
  any classes cannot be matched, a warning lists the unmatched classes
  and shows the
  [`ifcb_get_mat_variable()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_mat_variable.md)
  command to inspect available classes.

- The function writes one MAT file per sample using
  [`ifcb_create_manual_file()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_manual_file.md).

## References

Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification
of phytoplankton sampled with imaging-in-flow cytometry. Limnol.
Oceanogr: Methods 5, 204–216.

## See also

[`ifcb_py_install`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md)
[`ifcb_create_class2use`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_class2use.md)
<https://github.com/hsosik/ifcb-analysis>

## Examples

``` r
if (FALSE) { # \dontrun{
# Example: Annotate a single IFCB sample
sample_names <- "D20220712T210855_IFCB134"
png_folder <- "data/annotated_png_images/"
adc_folder <- "data/raw"
class2use_file <- "data/manual/class2use.mat"
output_folder <- "data/manual/"

# Create manual MAT file for this sample
ifcb_annotate_samples(
  png_folder = png_folder,
  adc_folder = adc_folder,
  class2use_file = class2use_file,
  output_folder = output_folder,
  sample_names = sample_names
)
} # }
```
