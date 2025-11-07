# Get Shark Column Names

This function reads SHARK column names from a specified tab-separated
values (TSV) file included in the package. These columns are used for
submitting IFCB data to <https://shark.smhi.se/>.

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
#>  [1] MYEAR                  STATN                  SAMPLING_PLATFORM     
#>  [4] PROJ                   ORDERER                SHIPC                 
#>  [7] CRUISE_NO              DATE_TIME              SDATE                 
#> [10] STIME                  TIMEZONE               LATIT                 
#> [13] LONGI                  POSYS                  WADEP                 
#> [16] MPROG                  MNDEP                  MXDEP                 
#> [19] SLABO                  ACKR_SMP               SMTYP                 
#> [22] PDMET                  SMVOL                  METFP                 
#> [25] IFCBNO                 SMPNO                  LATNM                 
#> [28] SFLAG                  LATNM_SFLAG            TRPHY                 
#> [31] APHIA_ID               IMAGE_VERIFICATION     VERIFIED_BY           
#> [34] COUNT                  ABUND                  BIOVOL                
#> [37] C_CONC                 QFLAG                  COEFF                 
#> [40] CLASS_NAME             CLASS_F1               UNCLASSIFIED_COUNTS   
#> [43] UNCLASSIFIED_ABUNDANCE UNCLASSIFIED_VOLUME    METOA                 
#> [46] ASSOCIATED_MEDIA       CLASSPROG              ALABO                 
#> [49] ACKR_ANA               ANADATE                METDC                 
#> [52] TRAINING_SET           CLASSIFIER_USED        MANUAL_QC_DATE        
#> [55] PRE_FILTER_SIZE        PH_FB                  CHL_FB                
#> [58] CDOM_FB                PHYC_FB                PHER_FB               
#> [61] WATERFLOW_FB           TURB_FB                PCO2_FB               
#> [64] TEMP_FB                PSAL_FB                OSAT_FB               
#> [67] DOXY_FB               
#> <0 rows> (or 0-length row.names)

shark_colnames_minimal <- ifcb_get_shark_colnames(minimal = TRUE)
print(shark_colnames_minimal)
#>  [1] MYEAR               STATN               PROJ               
#>  [4] ORDERER             SHIPC               SDATE              
#>  [7] STIME               LATIT               LONGI              
#> [10] POSYS               MNDEP               MXDEP              
#> [13] SLABO               ACKR_SMP            SMTYP              
#> [16] SMVOL               IFCBNO              SMPNO              
#> [19] LATNM               SFLAG               TRPHY              
#> [22] IMAGE_VERIFICATION  VERIFIED_BY         COUNT              
#> [25] QFLAG               COEFF               CLASS_F1           
#> [28] UNCLASSIFIED_COUNTS METOA               ASSOCIATED_MEDIA   
#> [31] CLASSPROG           TRAINING_SET        ALABO              
#> [34] ACKR_ANA            ANADATE             METDC              
#> [37] CLASSIFIER_USED    
#> <0 rows> (or 0-length row.names)
```
