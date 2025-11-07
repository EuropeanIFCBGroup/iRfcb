# Adjust Classifications in Manual Annotations

This function adjusts the classifications in manual annotation files
based on a class2use file. It loads a specified class2use file and
applies the adjustments to all relevant files in the specified manual
folder. Optionally, it can also perform compression on the output files.
This is the R equivalent function of
`start_mc_adjust_classes_user_training` from the
`ifcb-analysis repository` (Sosik and Olson 2007).

## Usage

``` r
ifcb_adjust_classes(class2use_file, manual_folder, do_compression = TRUE)
```

## Arguments

- class2use_file:

  A character string representing the full path to the class2use file
  (should be a .mat file).

- manual_folder:

  A character string representing the path to the folder containing
  manual annotation files. The function will look for files starting
  with 'D' in this folder.

- do_compression:

  A logical value indicating whether to apply compression to the output
  files. Defaults to TRUE.

## Value

None

## Details

Python must be installed to use this function. The required python
packages can be installed in a virtual environment using
[`ifcb_py_install()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md).

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
# Initialize a python session if not already set up
ifcb_py_install()

ifcb_adjust_classes("data/config/class2use.mat",
                    "data/manual/2014/")
} # }
```
