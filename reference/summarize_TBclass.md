# Summarize TreeBagger Classifier Results

This function reads a TreeBagger classifier result file (`.mat` format)
and summarizes the number of targets in each class based on the
classification scores and thresholds.

## Usage

``` r
summarize_TBclass(classfile, adhocthresh = NULL)
```

## Arguments

- classfile:

  Character string specifying the path to the TreeBagger classifier
  result file (`.mat` format).

- adhocthresh:

  Numeric vector specifying the adhoc thresholds for each class. If NULL
  (default), no adhoc thresholding is applied. If a single numeric value
  is provided, it is applied to all classes.

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
