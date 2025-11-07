# Get Variable Names from a MAT File

This function reads a `.mat` file generated the `ifcb-analysis`
repository (Sosik and Olson 2007) and retrieves the names of all
variables stored within it.

## Usage

``` r
ifcb_get_mat_names(mat_file, use_python = FALSE)
```

## Arguments

- mat_file:

  A character string specifying the path to the .mat file.

- use_python:

  Logical. If `TRUE`, attempts to read the `.mat` file using a
  Python-based method. Default is `FALSE`.

## Value

A character vector of variable names.

## Details

If `use_python = TRUE`, the function tries to read the `.mat` file using
[`ifcb_read_mat()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_mat.md),
which relies on `SciPy`. This approach may be faster than the default
approach using
[`R.matlab::readMat()`](https://rdrr.io/pkg/R.matlab/man/readMat.html),
especially for large `.mat` files. To enable this functionality, ensure
Python is properly configured with the required dependencies. You can
initialize the Python environment and install necessary packages using
[`ifcb_py_install()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md).

If `use_python = FALSE` or if `SciPy` is not available, the function
falls back to using
[`R.matlab::readMat()`](https://rdrr.io/pkg/R.matlab/man/readMat.html).

## References

Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification
of phytoplankton sampled with imaging-in-flow cytometry. Limnol.
Oceanogr: Methods 5, 204–216.

## See also

[`ifcb_get_mat_variable`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_mat_variable.md)
<https://github.com/hsosik/ifcb-analysis>

## Examples

``` r
# Example .mat file included in the package
mat_file <- system.file("exdata/example.mat", package = "iRfcb")

# Get variable names from a MAT file
variables <- ifcb_get_mat_names(mat_file)
print(variables)
#> [1] "roinum"                  "TBclass"                
#> [3] "TBscores"                "TBclass_above_threshold"
#> [5] "class2useTB"             "classifierName"         
```
