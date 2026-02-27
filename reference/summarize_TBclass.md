# Summarize TreeBagger Classifier Results

This function reads a TreeBagger classifier result file (`.mat` or `.h5`
format) and summarizes the number of targets in each class based on the
classification scores and thresholds.

## Usage

``` r
summarize_TBclass(classfile, adhocthresh = NULL, use_python = FALSE)
```

## Arguments

- classfile:

  Character string specifying the path to the classifier result file
  (`.mat` or `.h5` format).

- adhocthresh:

  Numeric vector specifying the adhoc thresholds for each class. If NULL
  (default), no adhoc thresholding is applied. If a single numeric value
  is provided, it is applied to all classes. Not available for `.h5`
  files.

- use_python:

  Logical. If `TRUE`, uses Python-based reading for `.mat` files.
  Default is `FALSE`.

## Value

A list containing three elements:

- classcount:

  Numeric vector of counts for each class based on the winning class
  assignment.

- classcount_above_optthresh:

  Numeric vector of counts for each class above the optimal threshold
  for maximum accuracy.

- classcount_above_adhocthresh:

  Numeric vector of counts for each class above the specified adhoc
  thresholds (if provided).
