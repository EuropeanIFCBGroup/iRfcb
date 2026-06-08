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
  packages = NULL,
  features = FALSE,
  features_ref = NULL
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

- features:

  Logical. If `TRUE`, additionally installs the WHOI `ifcb-features`
  package (<https://github.com/WHOIGit/ifcb-features>) from GitHub,
  together with its dependencies (`pyifcb`, `phasepack`, `scikit-image`,
  `scikit-learn`). This is required by
  [`ifcb_extract_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_features.md).
  Default is `FALSE` to keep the default environment lightweight. When
  installing into an existing virtual environment, the (slow) install is
  skipped if `ifcb-features` already imports successfully, unless
  `features_ref` is given. Installation requires binary wheels for all
  of `pyifcb`'s dependencies (notably `h5py`); if no wheel is available
  for your Python version, installation will fail. See
  <https://github.com/WHOIGit/ifcb-features> for current Python version
  requirements.

- features_ref:

  A character string specifying which git reference (release tag,
  branch, or commit) of `ifcb-features` to install when
  `features = TRUE`. If `NULL` (default), the latest published GitHub
  release is installed, which is more stable than the actively developed
  default branch. Use `features_ref = "main"` to install the latest
  development commit, or a tag such as `"v1.0.0"` to pin a specific
  version.

## Value

No return value. This function is called for its side effect of
configuring the Python environment.

## Details

This function requires Python to be available on the system. It uses the
`reticulate` package to manage Python environments and packages.

The `USE_IRFCB_PYTHON` environment variable can be set to `"TRUE"` to
automatically activate an installed Python venv when the `iRfcb` package
is loaded. By default this activates a venv named `iRfcb` found in
[`reticulate::virtualenv_root()`](https://rstudio.github.io/reticulate/reference/virtualenv-tools.html)
(available via
[`reticulate::virtualenv_list()`](https://rstudio.github.io/reticulate/reference/virtualenv-tools.html);
see examples). To activate a specific environment instead, also set the
`IRFCB_PYTHON_VENV` variable to either the name of a venv under
[`reticulate::virtualenv_root()`](https://rstudio.github.io/reticulate/reference/virtualenv-tools.html)
or a full path to a venv directory. Both variables can be set in your
`.Renviron` file to enable automatic setup across sessions. For more
details, see the package README at
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

# Install the iRfcb Python venv including the WHOI ifcb-features package
# (latest release by default)
ifcb_py_install(envname = envpath, features = TRUE)

# Install a specific ifcb-features version, or the development branch
ifcb_py_install(envname = envpath, features = TRUE, features_ref = "v1.0.0")
ifcb_py_install(envname = envpath, features = TRUE, features_ref = "main")

# Use system Python instead of a virtual environment
ifcb_py_install(envname = envpath, use_venv = FALSE)
} # }
```
