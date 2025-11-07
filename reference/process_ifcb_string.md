# Process IFCB String

This helper function processes IFCB (Imaging FlowCytobot) filenames and
extracts the date component in `YYYYMMDD` format. It supports two
formats:

- `IFCB1_2014_188_222013`: Extracts the date using year and day-of-year
  information.

- `D20240101T120000_IFCB1`: Extracts the date directly from the
  timestamp.

## Usage

``` r
process_ifcb_string(ifcb_string, quiet = FALSE)
```

## Arguments

- ifcb_string:

  A character vector of IFCB filenames to process.

- quiet:

  A logical indicating whether to suppress messages for unknown formats.
  Defaults to `FALSE`.

## Value

A character vector containing extracted dates in `YYYYMMDD` format, or
`NA` for unknown formats.

## Examples

``` r
# Example 1: Process a string in the 'IFCB1_2014_188_222013' format
process_ifcb_string("IFCB1_2014_188_222013")
#> [1] "D20140707"

# Example 2: Process a string in the 'D20240101T120000_IFCB1' format
process_ifcb_string("D20240101T120000_IFCB1")
#> [1] "D20240101"

# Example 3: Process an unknown format
process_ifcb_string("UnknownFormat_12345")
#> Unknown format: UnknownFormat_12345
#> [1] NA
```
