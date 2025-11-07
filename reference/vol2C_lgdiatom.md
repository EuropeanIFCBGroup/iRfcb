# Convert Biovolume to Carbon for Large Diatoms

This function converts biovolume in microns^3 to carbon in picograms for
large diatoms (\> 2000 micron^3) according to Menden-Deuer and Lessard
2000. The formula used is: log pgC cell^-1 = log a + b \* log V (um^3),
with log a = -0.933 and b = 0.881 for diatoms \> 3000 um^3.

## Usage

``` r
vol2C_lgdiatom(volume)
```

## Arguments

- volume:

  A numeric vector of biovolume measurements in microns^3.

## Value

A numeric vector of carbon measurements in picograms.

## Examples

``` r
# Volumes in microns^3
volume <- c(5000, 10000, 20000)

# Convert biovolume to carbon for large diatoms
vol2C_lgdiatom(volume)
#> [1] 211.7350 389.9420 718.1372
```
