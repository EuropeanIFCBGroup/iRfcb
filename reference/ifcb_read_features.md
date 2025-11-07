# Read Feature Files from a Specified Folder or File Paths

This function reads feature files from a given folder or a specified set
of file paths, optionally filtering them based on whether they are
multiblob or single blob files.

## Usage

``` r
ifcb_read_features(
  feature_files = NULL,
  multiblob = FALSE,
  feature_version = NULL,
  verbose = TRUE
)
```

## Arguments

- feature_files:

  A path to a folder containing feature files or a character vector of
  file paths.

- multiblob:

  Logical indicating whether to filter for multiblob files (default:
  FALSE).

- feature_version:

  Optional numeric or character version to filter feature files by (e.g.
  2 for "\_v2"). Default is NULL (no filtering).

- verbose:

  Logical. Whether to display progress information. Default is TRUE.

## Value

A named list of data frames, where each element corresponds to a feature
file read from `feature_files`. The list is named with the base names of
the feature files.

## Examples

``` r
if (FALSE) { # \dontrun{
# Read feature files from a folder
features <- ifcb_read_features("path/to/feature_folder")

# Read only multiblob feature files
multiblob_features <- ifcb_read_features("path/to/feature_folder", multiblob = TRUE)

# Read only version 4 feature files
v4_features <- ifcb_read_features("path/to/feature_folder", feature_version = 4)

# Read feature files from a list of file paths
features <- ifcb_read_features(c("path/to/file1.csv", "path/to/file2.csv"))
} # }
```
