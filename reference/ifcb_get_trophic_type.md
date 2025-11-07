# Get Trophic Type for a List of Plankton Taxa

This function matches a specified list of taxa with a summarized list of
trophic types for various plankton taxa from Northern Europe (data
sourced from `SMHI Trophic Type`).

## Usage

``` r
ifcb_get_trophic_type(taxa_list = NULL, print_complete_list = FALSE)
```

## Arguments

- taxa_list:

  A character vector of scientific names for which trophic types are to
  be retrieved.

- print_complete_list:

  Logical, if TRUE, prints the complete list of summarized trophic
  types.

## Value

A character vector of trophic types corresponding to the scientific
names in `taxa_list`, or a data frame containing all taxa and trophic
types available in the `SMHI Trophic Type` list. The available trophic
types are autotrophic (AU), heterotrophic (HT), mixotrophic (MX) or not
specified (NS).

## Details

If there are multiple trophic types for a scientific name (i.e. AU and
HT size classes), the summarized trophic type is "NS".

## Examples

``` r
# Example usage:
taxa_list <- c("Acanthoceras zachariasii",
               "Nodularia spumigena",
               "Acanthoica quattrospina",
               "Noctiluca",
               "Gymnodiniales")

ifcb_get_trophic_type(taxa_list)
#> [1] "AU" "AU" "MX" "HT" "NS"
```
