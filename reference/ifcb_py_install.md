# Install iRfcb Python Environment

This function sets up the Python environment for `iRfcb`. By default, it
creates and activates a Python virtual environment (`venv`) named
"iRfcb" and installs the required Python packages from the
"requirements.txt" file. Alternatively, users can opt to use the system
Python instead of creating a virtual environment by setting
`use_venv = FALSE` (not recommended).

## Usage

``` r
ifcb_py_install(
  envname = "~/.virtualenvs/iRfcb",
  use_venv = TRUE,
  packages = NULL
)
```

## Arguments

- envname:

  A character string specifying the name of the virtual environment to
  create. Default is "~/.virtualenvs/iRfcb".

- use_venv:

  Logical. If `TRUE` (default), a virtual environment is created. If
  `FALSE`, the system Python is used instead, and missing packages are
  installed globally for the user.

- packages:

  A character vector of additional Python packages to install. If NULL
  (default), only the packages from "requirements.txt" are installed.

## Value

No return value. This function is called for its side effect of
configuring the Python environment.

## Details

This function requires Python to be available on the system. It uses the
`reticulate` package to manage Python environments and packages.

The `USE_IRFCB_PYTHON` environment variable can be set to automatically
activate an installed Python venv named `iRfcb` when the `iRfcb` package
is loaded. Ensure that the `iRfcb` venv is installed in
[`reticulate::virtualenv_root()`](https://rstudio.github.io/reticulate/reference/virtualenv-tools.html)
and available via
[`reticulate::virtualenv_list()`](https://rstudio.github.io/reticulate/reference/virtualenv-tools.html)
(see examples). You can set `USE_IRFCB_PYTHON` to `"TRUE"` in your
`.Renviron` file to enable automatic setup. For more details, see the
package README at
<https://europeanifcbgroup.github.io/iRfcb/#python-dependency>.

## Examples

``` r
if (FALSE) { # \dontrun{
# Define the name of the virtual environment in your virtual_root directory
envpath <- file.path(reticulate::virtualenv_root(), "iRfcb")

# Install the iRfcb Python venv in your virtual_root directory
ifcb_py_install(envname = envpath)

# Install the iRfcb Python environment with additional packages
ifcb_py_install(envname = envpath, packages = c("numpy", "plotly"))

# Use system Python instead of a virtual environment
ifcb_py_install(envname = envpath, use_venv = FALSE)
} # }
```
