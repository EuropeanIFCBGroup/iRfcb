# Function to Read Individual Files and Extract Relevant Lines

This function reads an HDR file and extracts relevant lines containing
parameters and their values.

## Usage

``` r
read_hdr_file(file)
```

## Arguments

- file:

  A character string specifying the path to the HDR file.

## Value

A data frame with columns: `parameter`, `value`, and `file.`
