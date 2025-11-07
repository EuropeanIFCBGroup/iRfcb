# Read IFCB Header File and Extract Runtime Information

This function imports an IFCB header file (either from a local path or
URL), extracts specific target values such as runtime and inhibittime,
and returns them in a structured format (in seconds). This is the R
equivalent function of `IFCBxxx_readhdr` from the `ifcb-analysis`
repository (Sosik and Olson 2007).

## Usage

``` r
ifcb_get_runtime(hdr_file)
```

## Arguments

- hdr_file:

  A character string specifying the full path to the .hdr file or URL.

## Value

A list (hdr) containing runtime, inhibittime, and runType (if available)
extracted from the header file.

## References

Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification
of phytoplankton sampled with imaging-in-flow cytometry. Limnol.
Oceanogr: Methods 5, 204–216.

## See also

<https://github.com/hsosik/ifcb-analysis>

## Examples

``` r
if (FALSE) { # \dontrun{
# Example: Read and extract information from an IFCB header file
hdr_info <- ifcb_get_runtime("path/to/IFCB_hdr_file.hdr")

print(hdr_info)
} # }
```
