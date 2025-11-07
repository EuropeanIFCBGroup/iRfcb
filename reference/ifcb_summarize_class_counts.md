# Count Cells from TreeBagger Classifier Output

This function summarizes class results for a series of classifier output
files and returns a summary data list.

## Usage

``` r
ifcb_summarize_class_counts(
  classpath_generic,
  hdr_folder,
  year_range,
  use_python = FALSE
)
```

## Arguments

- classpath_generic:

  Character string specifying the location of the classifier output
  files. The path should include 'xxxx' in place of the 4-digit year
  (e.g., 'classxxxx_v1/').

- hdr_folder:

  Character string specifying the directory where the data (hdr files)
  are located. This can be a URL for web services or a full path for
  local files.

- year_range:

  Numeric vector specifying the range of years (e.g., 2013:2014) to
  process.

- use_python:

  Logical. If `TRUE`, attempts to read the `.mat` file using a
  Python-based method. Default is `FALSE`.

## Value

A list containing the following elements:

- class2useTB:

  Classes used in the TreeBagger classifier.

- classcountTB:

  Counts of each class considering each target placed in the winning
  class.

- classcountTB_above_optthresh:

  Counts of each class considering only classifications above the
  optimal threshold for maximum accuracy.

- ml_analyzedTB:

  Volume analyzed for each file.

- mdateTB:

  Dates associated with each file.

- filelistTB:

  List of files processed.

- classpath_generic:

  The generic classpath provided as input.

- classcountTB_above_adhocthresh (optional):

  Counts of each class considering only classifications above the adhoc
  threshold.

- adhocthresh (optional):

  The adhoc threshold used for classification.

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

## Examples

``` r
if (FALSE) { # \dontrun{
ifcb_summarize_class_counts('path/to/class/classxxxx_v1/',
                            'path/to/data/', 2014)
} # }
```
