# Create a class2use `.mat` File

This function creates a `.mat` file containing a character vector of
class names. A class2use file can be used for manual annotation using
the code in the `ifcb-analysis` repository (Sosik and Olson 2007).

## Usage

``` r
ifcb_create_class2use(classes, filename, do_compression = TRUE)
```

## Arguments

- classes:

  A character vector of class names to be saved in the `.mat` file.

- filename:

  A string specifying the output file path (with `.mat` extension).

- do_compression:

  A logical value indicating whether to compress the `.mat` file.
  Defaults to `TRUE`.

## Value

No return value. This function is called for its side effect of creating
a `.mat` file.

## Details

The `.mat` file is written directly from R, producing output identical
to the MATLAB `ifcb-analysis` format.

## References

Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification
of phytoplankton sampled with imaging-in-flow cytometry. Limnol.
Oceanogr: Methods 5, 204–216.

## See also

[`ifcb_adjust_classes`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_adjust_classes.md)
<https://github.com/hsosik/ifcb-analysis>

## Examples

``` r
if (FALSE) { # \dontrun{
# Example usage:
classes <- c("unclassified", "Dinobryon_spp", "Helicostomella_spp")

ifcb_create_class2use(classes, "class2use_output.mat", do_compression = TRUE)
} # }
```
