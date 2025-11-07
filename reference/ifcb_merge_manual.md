# Merge IFCB Manual Classification Data

This function merges two sets of manual classification data by combining
and aligning class labels from a base set and an additional set of
classifications. The merged `.mat` data can be used with the code in the
`ifcb-analysis` repository (Sosik and Olson 2007).

## Usage

``` r
ifcb_merge_manual(
  class2use_file_base,
  class2use_file_additions,
  class2use_file_output = NULL,
  manual_folder_base,
  manual_folder_additions,
  manual_folder_output,
  do_compression = TRUE,
  temp_index_offset = 50000,
  skip_class = NULL,
  quiet = FALSE
)
```

## Arguments

- class2use_file_base:

  Character. Path to the `class2use` file of the base manual
  classifications. The base set contains the original manual
  classifications list that form the foundation for merging.

- class2use_file_additions:

  Character. Path to the `class2use` file of the additions manual
  classifications. The additions set contains additional classifications
  that need to be merged with the base set. Class labels from the
  `class2use_file_additions` that are not already included in the
  `class2use_file_base` will be added to generate the
  `class2use_file_output`.

- class2use_file_output:

  Character. Path where the merged `class2use` file will be saved. If
  `NULL`, the merged file will be stored in the same directory as
  `class2use_file_base`. Default is `NULL`.

- manual_folder_base:

  Character. Path to the folder containing the base set of manual
  classification `.mat` files.

- manual_folder_additions:

  Character. Path to the folder containing the additions set of manual
  classification `.mat` files.

- manual_folder_output:

  Character. Path to the output folder where the merged classification
  files will be stored.

- do_compression:

  A logical value indicating whether to compress the `.mat` file.
  Defaults to `TRUE`.

- temp_index_offset:

  Numeric. A large integer used to generate temporary indices during the
  merge process. Default is 50000.

- skip_class:

  Character. A vector of class names to skip from the
  `class2use_file_additions` during the merge process. Default is
  `NULL`.

- quiet:

  Logical. If `TRUE`, suppresses output messages. Default is `FALSE`.

## Value

No return value. Outputs the combined `class2use` file in the same
folder as `class2use_file_base` is located or at a user-specified
location, and merged `.mat` files into the output folder.

## Details

Python must be installed to use this function. The required python
packages can be installed in a virtual environment using
[`ifcb_py_install()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md).

The **base** set consists of the original classifications that are used
as a reference for the merging process. The **additions** set contains
the additional classifications that need to be merged with the base set.
When merging, unique class names from the additions set that are not
present in the base set are appended.

The function works by aligning the class labels from the additions set
with those in the base set, handling conflicts by using a temporary
index system. It copies `.mat` files from both the base and additions
folders into the output folder, while adjusting indices and and class
names for the additions.

Note that the maximum limit for `uint16` is 65,535, so ensure that
`temp_index_offset` remains below this value.

## References

Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification
of phytoplankton sampled with imaging-in-flow cytometry. Limnol.
Oceanogr: Methods 5, 204–216.

## See also

[`ifcb_py_install`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md)
<https://github.com/hsosik/ifcb-analysis>

## Examples

``` r
if (FALSE) { # \dontrun{
ifcb_merge_manual("path/to/class2use_base.mat", "path/to/class2use_additions.mat",
                  "path/to/class2use_combined.mat", "path/to/manual/base_folder",
                  "path/to/manual/additions_folder", "path/to/manual/output_folder",
                  do_compression = TRUE, temp_index_offset = 50000, quiet = FALSE)
} # }
```
