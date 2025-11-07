# Convert IFCB Filenames to Timestamps

This function converts IFCB filenames to a data frame with separate
columns for the sample name, full timestamp, year, month, day, time, and
IFCB number. ROI numbers are included if available.

## Usage

``` r
ifcb_convert_filenames(filenames, tz = "UTC")
```

## Arguments

- filenames:

  A character vector of IFCB filenames in the format
  "DYYYYMMDDTHHMMSS_IFCBxxx" or "IFCBxxx_YYYY_DDD_HHMMSS". Filenames can
  optionally include an ROI number, which will be extracted if present.

- tz:

  Character. Time zone to assign to the extracted timestamps. Defaults
  to "UTC". Set this to a different time zone if needed.

## Value

A tibble with the following columns:

- `sample`: The extracted sample name (character).

- `full_timestamp`: The full timestamp in "YYYY-MM-DD HH:MM:SS" format
  (POSIXct).

- `year`: The year extracted from the timestamp (integer).

- `month`: The month extracted from the timestamp (integer).

- `day`: The day extracted from the timestamp (integer).

- `time`: The extracted time in "HH:MM:SS" format (character).

- `ifcb_number`: The IFCB instrument number (character).

- `roi`: The extracted ROI number if available (integer or `NA`).

If the `roi` column is empty (all `NA`), it will be excluded from the
output.

## Examples

``` r
filenames <- c("D20230314T001205_IFCB134", "D20230615T123045_IFCB135")
timestamps <- ifcb_convert_filenames(filenames)
print(timestamps)
#>                     sample           timestamp       date year month day
#> 1 D20230314T001205_IFCB134 2023-03-14 00:12:05 2023-03-14 2023     3  14
#> 2 D20230615T123045_IFCB135 2023-06-15 12:30:45 2023-06-15 2023     6  15
#>       time ifcb_number
#> 1 00:12:05     IFCB134
#> 2 12:30:45     IFCB135
```
