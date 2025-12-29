# Create an Empty Manual Classification MAT File

**\[deprecated\]**

This function was deprecated as it has been replaced by the function:
[`ifcb_create_manual_file()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_create_manual_file.md).

Generates a MAT file for IFCB data with an empty manual classification
structure using a specified number of ROIs, class names, and saves it to
a specified output file. This function utilizes a Python script for
creating the structure.

## Usage

``` r
ifcb_create_empty_manual_file(
  roi_length,
  class2use,
  output_file,
  classlist = 1,
  do_compression = TRUE,
  unclassified_id = deprecated()
)
```

## Arguments

- roi_length:

  Integer. The number of rows in the class list (number of ROIs).

- class2use:

  Character vector. The names of the classes to include in the
  `class2use_manual` field of the MAT file.

- output_file:

  Character. The path where the output MAT file will be saved.

- classlist:

  Integer or numeric vector. Defines the values for the second column of
  the class list, typically representing the manual classification
  labels:

  - If a single value is provided, all rows will be assigned this value.
    For example, all ROIs can be assigned to class index 1 (default),
    which typically represents the unclassified category.

  - If a numeric vector of the same length as `roi_length` is provided,
    the corresponding values will be used per row.

- do_compression:

  A logical value indicating whether to compress the .mat file. Default
  is TRUE.

- unclassified_id:

  **\[deprecated\]** `ifcb_create_empty_manual_file` now handles
  multiple classlist values. Use `classlist` instead.

## Value

No return value. This function is called for its side effects. The
created MAT file is saved at the specified `output_file` location.

## Details

Python must be installed to use this function. The required python
packages can be installed in a virtual environment using
[`ifcb_py_install()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md).

## Examples

``` r
if (FALSE) { # \dontrun{
# Initialize a python session if not already set up
ifcb_py_install()

# Create a MAT file with 100 ROIs, using a vector of class names, and save it to "output.mat"
ifcb_create_empty_manual_file(roi_length = 100,
                              class2use = c("unclassified", "Aphanizomenon_spp"),
                              output_file = "output.mat")

# Create a MAT file with 50 unclassified ROIs (1) and 50 Aphanizomenon_spp (2) ROIs
ifcb_create_empty_manual_file(roi_length = 100,
                              class2use = c("unclassified", "Aphanizomenon_spp"),
                              output_file = "output.mat",
                              classlist = c(rep(1, 50), rep(2, 50)))
} # }
```
