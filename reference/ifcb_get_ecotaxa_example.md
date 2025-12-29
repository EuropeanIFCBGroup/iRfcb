# Get EcoTaxa Column Names

This function reads an example EcoTaxa metadata file included in the
`iRfcb` package.

## Usage

``` r
ifcb_get_ecotaxa_example(example = "ifcb")
```

## Arguments

- example:

  A character string specifying which example EcoTaxa metadata file to
  load. Options are:

  "minimal"

  :   Loads a minimal example, for fully manual entry.

  "full_unknown"

  :   Loads a full featured example, with unknown objects only.

  "full_classified"

  :   Loads a full featured example, with already classified objects.

  "ifcb"

  :   (Default) Loads a full IFCB-specific dataset used for EcoTaxa
      submissions.

## Value

A data frame containing EcoTaxa example metadata.

## Details

This function loads different types of EcoTaxa metadata examples based
on the user's need. The examples include a minimal template for manual
data entry, as well as fully featured datasets with or without
classified objects. The default is an IFCB-specific example, originating
from <https://github.com/VirginieSonnet/IFCBdatabaseToEcotaxa>. The
example headers can used when submitting data from Imaging FlowCytobot
(IFCB) instruments to EcoTaxa at <https://ecotaxa.obs-vlfr.fr/>.

## Examples

``` r
ecotaxa_example <- ifcb_get_ecotaxa_example()

# Print the first five columns
print(ecotaxa_example)
#> # A tibble: 3 × 282
#>   img_file_name          object_id object_lat object_lon object_date object_time
#>   <chr>                  <chr>     <chr>      <chr>      <chr>       <chr>      
#> 1 [t]                    [t]       [f]        [f]        [t]         [t]        
#> 2 D20230915T093804_IFCB… D2023091… 57.7281986 11.468154… 20230915    93804      
#> 3 D20230915T113552_IFCB… D2023091… 57.866921… 11.2940889 20230915    113552     
#> # ℹ 276 more variables: object_link <chr>, object_depth_min <chr>,
#> #   object_depth_max <chr>, object_annotation_status <chr>,
#> #   object_annotation_person_name <chr>, object_annotation_person_email <chr>,
#> #   object_annotation_date <chr>, object_annotation_time <chr>,
#> #   object_annotation_category <chr>, object_aphiaid <chr>,
#> #   object_annotation_hierarchy <chr>, object_roi_number <chr>,
#> #   object_area <chr>, object_biovolume <chr>, …
```
