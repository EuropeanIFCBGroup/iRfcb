# Create a MANIFEST.txt File

This function generates a MANIFEST.txt file listing all files in a
specified folder and its subfolders, along with their sizes in bytes.
The function can optionally exclude an existing MANIFEST.txt file from
the generated list. A manifest may be useful when archiving images in
data repositories.

## Usage

``` r
ifcb_create_manifest(
  folder_path,
  manifest_path = file.path(folder_path, "MANIFEST.txt"),
  exclude_manifest = TRUE
)
```

## Arguments

- folder_path:

  A character string specifying the path to the folder whose files are
  to be listed.

- manifest_path:

  A character string specifying the path and name of the MANIFEST.txt
  file to be created. Defaults to "folder_path/MANIFEST.txt".

- exclude_manifest:

  A logical value indicating whether to exclude an existing MANIFEST.txt
  file from the list. Defaults to TRUE.

## Value

No return value, called for side effects. Creates a MANIFEST.txt file at
the specified location.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a MANIFEST.txt file for the current directory
ifcb_create_manifest(".")

# Create a MANIFEST.txt file for a specific directory, excluding an existing MANIFEST.txt file
ifcb_create_manifest("path/to/directory")

# Create a MANIFEST.txt file and save it to a specific path
ifcb_create_manifest("path/to/directory", manifest_path = "path/to/manifest/MANIFEST.txt")

# Create a MANIFEST.txt file without excluding an existing MANIFEST.txt file
ifcb_create_manifest("path/to/directory", exclude_manifest = FALSE)
} # }
```
