# Function to Create MANIFEST.txt

This function generates a MANIFEST.txt file that lists all files in the
specified paths, along with their sizes. It recursively includes files
from directories and skips paths that do not exist. The manifest
excludes the manifest file itself if present in the list.

## Usage

``` r
create_package_manifest(paths, manifest_path = "MANIFEST.txt", temp_dir)
```

## Arguments

- paths:

  A character vector of paths to files and/or directories to include in
  the manifest.

- manifest_path:

  A character string specifying the path to the manifest file. Default
  is "MANIFEST.txt".

- temp_dir:

  A character string specifying the temporary directory to be removed
  from the file paths.

## Value

This function does not return any value. It creates a `MANIFEST.txt`
file at the specified location, which contains a list of all files
(including their sizes) in the provided paths. The file paths are
relative to the specified `temp_dir`, and the manifest excludes the
manifest file itself if present.
