# Get Shark Column Example

This function reads a SHARK submission example from a file included in
the package. This format is used for submitting IFCB data to
<https://shark.smhi.se/>.

## Usage

``` r
ifcb_get_shark_example()
```

## Value

A data frame containing example data following the SHARK submission
format.

## See also

[`ifcb_get_shark_colnames`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_shark_colnames.md)

## Examples

``` r
shark_example <- ifcb_get_shark_example()

# Print example as tibble
dplyr::tibble(shark_example)
#> # A tibble: 5 × 67
#>   MYEAR STATN    SAMPLING_PLATFORM PROJ  ORDERER SHIPC CRUISE_NO DATE_TIME SDATE
#>   <int> <chr>    <chr>             <chr> <chr>   <chr>     <int> <chr>     <chr>
#> 1  2022 RV_FB_D… IFCB              IFCB… SMHI    77SE         12 2,02E+13  2022…
#> 2  2022 RV_FB_D… IFCB              IFCB… SMHI    77SE         12 2,02E+13  2022…
#> 3  2022 RV_FB_D… IFCB              IFCB… SMHI    77SE         12 2,02E+13  2022…
#> 4  2022 RV_FB_D… IFCB              IFCB… SMHI    77SE         12 2,02E+13  2022…
#> 5  2022 RV_FB_D… SveaFB            IFCB… SMHI    77SE         12 2,02E+13  2022…
#> # ℹ 58 more variables: STIME <chr>, TIMEZONE <chr>, LATIT <dbl>, LONGI <dbl>,
#> #   POSYS <chr>, WADEP <lgl>, MPROG <chr>, MNDEP <int>, MXDEP <int>,
#> #   SLABO <chr>, ACKR_SMP <chr>, SMTYP <chr>, PDMET <chr>, SMVOL <dbl>,
#> #   METFP <chr>, IFCBNO <chr>, SMPNO <chr>, LATNM <chr>, SFLAG <chr>,
#> #   LATNM_SFLAG <chr>, TRPHY <chr>, APHIA_ID <int>, IMAGE_VERIFICATION <chr>,
#> #   VERIFIED_BY <lgl>, COUNT <int>, ABUND <dbl>, BIOVOL <dbl>, C_CONC <dbl>,
#> #   QFLAG <lgl>, COEFF <dbl>, CLASS_NAME <chr>, CLASS_F1 <dbl>, …
```
