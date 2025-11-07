# Convert Biovolume to Carbon for Non-Diatom Protists

This function converts biovolume in microns^3 to carbon in picograms for
protists besides large diatoms (\> 3000 micron^3) according to
Menden-Deuer and Lessard 2000. The formula used is: log pgC cell^-1 =
log a + b \* log V (um^3), with log a = -0.665 and b = 0.939.

## Usage

``` r
vol2C_nondiatom(volume)
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

# Convert biovolume to carbon for non-diatom protists
vol2C_nondiatom(volume)
#> [1]  643.1804 1233.1048 2364.1072
```
