# Estimate Volume Analyzed from IFCB Header File

This function reads an IFCB header file to extract sample run time and
inhibittime, and returns the associated estimate of sample volume
analyzed (in milliliters). The function assumes a standard IFCB
configuration with a sample syringe operating at 0.25 mL per minute. For
IFCB instruments after 007 and higher (except 008). This is the R
equivalent function of `IFCB_volume_analyzed` from the `ifcb-analysis`
repository (Sosik and Olson 2007).

## Usage

``` r
ifcb_volume_analyzed(hdr_file, hdrOnly_flag = FALSE, flowrate = 0.25)
```

## Arguments

- hdr_file:

  A character vector specifying the path(s) to one or more .hdr files or
  URLs.

- hdrOnly_flag:

  An optional flag indicating whether to skip ADC file estimation
  (default is FALSE).

- flowrate:

  Milliliters per minute for syringe pump (default is 0.25).

## Value

A numeric vector containing the estimated sample volume analyzed for
each header file.

## References

Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification
of phytoplankton sampled with imaging-in-flow cytometry. Limnol.
Oceanogr: Methods 5, 204–216.

## See also

<https://github.com/hsosik/ifcb-analysis>

## Examples

``` r
if (FALSE) { # \dontrun{
# Example: Estimate volume analyzed from an IFCB header file
hdr_file <- "path/to/IFCB_hdr_file.hdr"
ml_analyzed <- ifcb_volume_analyzed(hdr_file)
print(ml_analyzed)
} # }
```
