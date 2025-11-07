# Estimate Volume Analyzed from IFCB ADC File

This function reads an IFCB ADC file to extract sample run time and
inhibittime, and returns the associated estimate of sample volume
analyzed (in milliliters). The function assumes a standard IFCB
configuration with a sample syringe operating at 0.25 mL per minute. For
IFCB instruments after 007 and higher (except 008). This is the R
equivalent function of `IFCB_volume_analyzed_fromADC` from the
`ifcb-analysis repository` (Sosik and Olson 2007).

## Usage

``` r
ifcb_volume_analyzed_from_adc(adc_file)
```

## Arguments

- adc_file:

  A character vector specifying the path(s) to one or more .adc files or
  URLs.

## Value

A list containing:

- **ml_analyzed**: A numeric vector of estimated sample volume analyzed
  for each ADC file.

- **inhibittime**: A numeric vector of inhibittime values extracted from
  ADC files.

- **runtime**: A numeric vector of runtime values extracted from ADC
  files.

## References

Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification
of phytoplankton sampled with imaging-in-flow cytometry. Limnol.
Oceanogr: Methods 5, 204–216.

## See also

<https://github.com/hsosik/ifcb-analysis>

## Examples

``` r
if (FALSE) { # \dontrun{
# Example: Estimate volume analyzed from an IFCB ADC file
adc_file <- "path/to/IFCB_adc_file.adc"
adc_info <- ifcb_volume_analyzed_from_adc(adc_file)
print(adc_info$ml_analyzed)
} # }
```
