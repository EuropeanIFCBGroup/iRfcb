# Convert Biovolume to Carbon for Diatoms (All Sizes)

This function converts biovolume in microns^3 to carbon in picograms for
diatoms across the full size range according to Menden-Deuer and Lessard
2000. The formula used is: log pgC cell^-1 = log a + b \* log V (um^3),
with log a = -0.541 and b = 0.811.

## Usage

``` r
vol2C_diatom(volume)
```

## Arguments

- volume:

  A numeric vector of biovolume measurements in microns^3.

## Value

A numeric vector of carbon measurements in picograms.

## Details

This relationship is fit to diatoms of all sizes and assigns a higher
carbon density than
[`vol2C_lgdiatom`](https://europeanifcbgroup.github.io/iRfcb/reference/vol2C_lgdiatom.md)
(which is specific to large diatoms larger than 3000 micron^3). Because
the large-diatom equation is intended only for cells \> 3000 micron^3,
switching equations at that threshold introduces a discontinuity: at
3000 micron^3 the all-sizes equation predicts ~190 pgC versus ~135 pgC
for the large-diatom equation. (The two curves themselves only intersect
near 4e5 micron^3.)

## References

Menden-Deuer Susanne, Lessard Evelyn J., (2000), Carbon to volume
relationships for dinoflagellates, diatoms, and other protist plankton,
Limnology and Oceanography, 45(3), 569-579, doi:
10.4319/lo.2000.45.3.0569.

## See also

[`vol2C_lgdiatom`](https://europeanifcbgroup.github.io/iRfcb/reference/vol2C_lgdiatom.md)
for the large-diatom (\> 3000 micron^3) relationship.

## Examples

``` r
# Volumes in microns^3
volume <- c(500, 1000, 2000)

# Convert biovolume to carbon for diatoms (all sizes)
vol2C_diatom(volume)
#> [1]  44.44927  77.98301 136.81551
```
