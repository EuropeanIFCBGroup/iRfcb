# Split Large Zip File into Smaller Parts

This helper function takes an existing zip file, extracts its contents,
and splits it into smaller zip files without splitting subfolders.

## Usage

``` r
split_large_zip(zip_file, max_size = 500, quiet = FALSE)
```

## Arguments

- zip_file:

  The path to the large zip file.

- max_size:

  The maximum size (in MB) for each split zip file. Default is 500 MB.

- quiet:

  Logical. If TRUE, suppresses messages about the progress and
  completion of the zip process. Default is FALSE.

## Value

This function does not return any value; it creates multiple smaller zip
files.

## Examples

``` r
if (FALSE) { # \dontrun{
# Split an existing zip file into parts of up to 500 MB
split_large_zip("large_file.zip", max_size = 500)
} # }
```
