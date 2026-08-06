# Convert Biovolume to Carbon for Diatoms, Choosing the Equation by Volume

This function converts biovolume in microns^3 to carbon in picograms for
diatoms, selecting between the two Menden-Deuer and Lessard (2000)
diatom relationships element-wise: volumes greater than 3000 micron^3
use the large-diatom equation
([`vol2C_lgdiatom`](https://europeanifcbgroup.github.io/iRfcb/reference/vol2C_lgdiatom.md)),
and the rest use the all-sizes equation
([`vol2C_diatom`](https://europeanifcbgroup.github.io/iRfcb/reference/vol2C_diatom.md)).
It backs `diatom_equation = "auto"` in
[`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
and
[`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md),
and applies to whatever volume it is handed: the ROI biovolume under
`carbon_conversion = "roi"`, or the per-cell volume under
`carbon_conversion = "cell"`.

## Usage

``` r
vol2C_diatom_auto(volume)
```

## Arguments

- volume:

  A numeric vector of biovolumes in microns^3.

## Value

A numeric vector of carbon content in picograms.

## Details

Be aware that the two relationships are not continuous at the 3000
micron^3 boundary: the all-sizes equation predicts about 190 pgC there
and the large-diatom equation about 135 pgC. Selecting between them by
volume therefore makes predicted carbon *drop* by roughly 41% as a cell
grows across the boundary, which is why this is not the default. Use it
when keeping each equation inside its calibrated size range matters more
than a monotonic carbon-to-volume curve.

## References

Menden-Deuer Susanne, Lessard Evelyn J., (2000), Carbon to volume
relationships for dinoflagellates, diatoms, and other protist plankton,
Limnology and Oceanography, 45(3), 569-579, doi:
10.4319/lo.2000.45.3.0569.

## See also

[`vol2C_diatom`](https://europeanifcbgroup.github.io/iRfcb/reference/vol2C_diatom.md)
[`vol2C_lgdiatom`](https://europeanifcbgroup.github.io/iRfcb/reference/vol2C_lgdiatom.md)

## Examples

``` r
# Volumes in microns^3, spanning the 3000 micron^3 boundary
volume <- c(500, 2000, 5000, 20000)

# Small volumes use the all-sizes equation, large ones the large-diatom equation
vol2C_diatom_auto(volume)
#> [1]  44.44927 136.81551 211.73496 718.13720
```
