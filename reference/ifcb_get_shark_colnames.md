# Get Shark Column Names

This function reads SHARK column names from a specified tab-separated
values (TSV) file included in the package. These columns are used for
submitting IFCB data to <https://shark.smhi.se/en/>.

## Usage

``` r
ifcb_get_shark_colnames(minimal = FALSE)
```

## Arguments

- minimal:

  A logical value indicating whether to load only the minimal set of
  column names required for data submission to SHARK. Default is FALSE.

## Value

An empty data frame containing the SHARK column names.

## Details

For a detailed example of a data submission, see
[`ifcb_get_shark_example`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_shark_example.md).

## See also

[`ifcb_get_shark_example`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_shark_example.md)

## Examples

``` r
shark_colnames <- ifcb_get_shark_colnames()
print(shark_colnames)
#> # A tibble: 0 × 67
#> # ℹ 67 variables: MYEAR <dbl>, STATN <chr>, SAMPLING_PLATFORM <chr>,
#> #   PROJ <chr>, ORDERER <chr>, SHIPC <chr>, CRUISE_NO <dbl>, DATE_TIME <dbl>,
#> #   SDATE <date>, STIME <time>, TIMEZONE <chr>, LATIT <dbl>, LONGI <dbl>,
#> #   POSYS <chr>, WADEP <lgl>, MPROG <chr>, MNDEP <dbl>, MXDEP <dbl>,
#> #   SLABO <chr>, ACKR_SMP <chr>, SMTYP <chr>, PDMET <chr>, SMVOL <dbl>,
#> #   METFP <chr>, IFCBNO <chr>, SMPNO <chr>, LATNM <chr>, SFLAG <chr>,
#> #   LATNM_SFLAG <chr>, TRPHY <chr>, APHIA_ID <dbl>, IMAGE_VERIFICATION <chr>, …

shark_colnames_minimal <- ifcb_get_shark_colnames(minimal = TRUE)
print(shark_colnames_minimal)
#> # A tibble: 0 × 37
#> # ℹ 37 variables: MYEAR <dbl>, STATN <chr>, PROJ <chr>, ORDERER <chr>,
#> #   SHIPC <chr>, SDATE <date>, STIME <time>, LATIT <dbl>, LONGI <dbl>,
#> #   POSYS <chr>, MNDEP <dbl>, MXDEP <dbl>, SLABO <chr>, ACKR_SMP <chr>,
#> #   SMTYP <chr>, SMVOL <dbl>, IFCBNO <chr>, SMPNO <chr>, LATNM <chr>,
#> #   SFLAG <chr>, TRPHY <chr>, IMAGE_VERIFICATION <chr>, VERIFIED_BY <lgl>,
#> #   COUNT <dbl>, QFLAG <lgl>, COEFF <dbl>, CLASS_F1 <dbl>,
#> #   UNCLASSIFIED_COUNTS <dbl>, METOA <chr>, ASSOCIATED_MEDIA <chr>, …
```
