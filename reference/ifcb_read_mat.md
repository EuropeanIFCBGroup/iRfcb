# Read a MATLAB .mat File in R

This function reads a MATLAB `.mat` file using a Python function via
`reticulate`.

## Usage

``` r
ifcb_read_mat(file_path)
```

## Arguments

- file_path:

  A character string representing the full path to the .mat file.

## Value

A list containing the MATLAB variables.

## Details

Python must be installed to use this function. The required python
packages can be installed in a virtual environment using
[`ifcb_py_install()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md).

This function requires a python interpreter to be installed. The
required python packages can be installed in a virtual environment using
[`ifcb_py_install()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md).

## See also

[`ifcb_py_install`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Initialize Python environment and install required packages
ifcb_py_install()

# Example .mat file included in the package
mat_file <- system.file("exdata/example.mat", package = "iRfcb")

# Read mat file using Python
data <- ifcb_read_mat(mat_file)
} # }
```
