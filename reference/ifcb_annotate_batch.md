# Annotate IFCB Images with Specified Class

This function creates or updates manual `.mat` classlist files with a
user specified class in batch, based on input vector of IFCB image
names. These `.mat` files can be used with the code in the
`ifcb-analysis` repository (Sosik and Olson 2007).

## Usage

``` r
ifcb_annotate_batch(
  png_images,
  class,
  manual_folder,
  adc_files,
  class2use_file,
  manual_output = NULL,
  manual_recursive = FALSE,
  unclassified_id = 1,
  do_compression = TRUE,
  adc_folder = deprecated()
)
```

## Arguments

- png_images:

  A character vector containing the names of the PNG images to be
  annotated in the format DYYYYMMDDTHHMMSS_IFCBXXX_ZZZZZ.png, where XXX
  represent the IFCB number and ZZZZZ the roi number.

- class:

  A character string or integer specifying the class name or class2use
  index to annotate the images with. If a string is provided, it is
  matched against the available classes in `class2use_file`.

- manual_folder:

  A character string specifying the path to the folder containing the
  manual `.mat` classlist files.

- adc_files:

  A character string specifying the path to the folder containing the
  raw data, organized in subfolders by year (YYYY) and date (DYYYYMMDD),
  or a vector with full paths to the `.adc` files. Each ADC file is used
  to determine the number of regions of interest (ROIs) for each sample
  when creating new manual `.mat` files.

- class2use_file:

  A character string specifying the path to the `.mat` file containing
  class names and corresponding indices.

- manual_output:

  A character string specifying the path to the folder where updated or
  newly created `.mat` classlist files will be saved. If not provided,
  the `manual_folder` path will be used by default.

- manual_recursive:

  A logical value indicating whether to search recursively within
  `manual_folder` for `.mat` files. Default is `FALSE`.

- unclassified_id:

  An integer specifying the class ID to use for unclassified regions of
  interest (ROIs) when creating new manual `.mat` files. Default is `1`.

- do_compression:

  A logical value indicating whether to compress the .mat file. Default
  is TRUE.

- adc_folder:

  **\[deprecated\]**

  Use `adc_files` instead.

## Value

The function does not return a value. It creates or updates `.mat` files
in the `manual_folder` to reflect the specified annotations.

## Details

Python must be installed to use this function. The required python
packages can be installed in a virtual environment using
[`ifcb_py_install()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md).

If an image belongs to a sample that already has a corresponding manual
`.mat` file, the function updates the class IDs for the specified
regions of interest (ROIs) in that file. If no manual file exists for
the sample, the function creates a new one based on the sample's ADC
data, assigning unclassified IDs to all ROIs initially, then applying
the specified class to the relevant ROIs.

The class parameter can be provided as either a string (class name) or
an integer (class index). If a string is provided, the function will
attempt to match it to one of the available classes in `class2use_file`.
If no match is found, an error is thrown.

The function assumes that the ADC files are organized in subfolders by
year (YYYY) and date (DYYYYMMDD) within `adc_files`.

## References

Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification
of phytoplankton sampled with imaging-in-flow cytometry. Limnol.
Oceanogr: Methods 5, 204–216.

## See also

[`ifcb_correct_annotation`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_correct_annotation.md),
[`ifcb_create_manual_file`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_manual_file.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Initialize a python session if not already set up
ifcb_py_install()

# Annotate two png images with class "Nodularia_spumigena" and update or create manual files
ifcb_annotate_batch(
  png_images = c("D20230812T162908_IFCB134_01399.png",
                 "D20230714T102127_IFCB134_00069.png"),
  class = "Nodularia_spumigena",
  manual_folder = "path/to/manual",
  adc_files = "path/to/adc",
  class2use_file = "path/to/class2use.mat"
)
} # }
```
