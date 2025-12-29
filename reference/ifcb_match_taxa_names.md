# Retrieve WoRMS Records with Retry Mechanism

**\[superseded\]**

This function has been superseded by `SHARK4R::match_worms_taxa()` or
[`worrms::wm_records_names()`](https://docs.ropensci.org/worrms/reference/wm_records_names.html).
It will not receive new features, but will continue to receive critical
bug fixes as needed.

This function attempts to retrieve WoRMS records using the provided taxa
names. It retries the operation if an error occurs, up to a specified
number of attempts.

## Usage

``` r
ifcb_match_taxa_names(
  taxa_names,
  best_match_only = TRUE,
  max_retries = 3,
  sleep_time = 10,
  marine_only = FALSE,
  return_list = FALSE,
  verbose = TRUE,
  fuzzy = deprecated()
)
```

## Arguments

- taxa_names:

  A character vector of taxa names to retrieve records for.

- best_match_only:

  A logical value indicating whether to automatically select the first
  match and return a single match. Default is TRUE.

- max_retries:

  An integer specifying the maximum number of attempts to retrieve
  records.

- sleep_time:

  A numeric value indicating the number of seconds to wait between retry
  attempts.

- marine_only:

  Logical. If TRUE, restricts the search to marine taxa only. Default is
  FALSE.

- return_list:

  A logical value indicating whether to to return the output as a list.
  Default is FALSE, where the result is returned as a dataframe.

- verbose:

  A logical indicating whether to print progress messages. Default is
  TRUE.

- fuzzy:

  **\[deprecated\]** The fuzzy argument is no longer available

## Value

A data frame (or list if return_list is TRUE) of WoRMS records or NULL
if the retrieval fails after the maximum number of attempts.

## Examples

``` r
# \donttest{
# Example: Retrieve WoRMS records for a list of taxa names
taxa <- c("Calanus finmarchicus", "Thalassiosira pseudonana", "Phaeodactylum tricornutum")

# Call the function
records <- ifcb_match_taxa_names(taxa_names = taxa,
                                 max_retries = 3,
                                 sleep_time = 5,
                                 marine_only = TRUE,
                                 verbose = TRUE)

# Print records as tibble
print(records)
#> # A tibble: 3 × 29
#>   name  AphiaID url   scientificname authority status unacceptreason taxonRankID
#>   <chr>   <int> <chr> <chr>          <chr>     <chr>  <lgl>                <int>
#> 1 Cala…  104464 http… Calanus finma… (Gunneru… accep… NA                     220
#> 2 Thal…  148934 http… Thalassiosira… Hasle & … unass… NA                     220
#> 3 Phae…  175584 http… Phaeodactylum… Bohlin, … unass… NA                     220
#> # ℹ 21 more variables: rank <chr>, valid_AphiaID <int>, valid_name <chr>,
#> #   valid_authority <chr>, parentNameUsageID <int>, originalNameUsageID <int>,
#> #   kingdom <chr>, phylum <chr>, class <chr>, order <chr>, family <chr>,
#> #   genus <chr>, citation <chr>, lsid <chr>, isMarine <int>, isBrackish <int>,
#> #   isFreshwater <int>, isTerrestrial <int>, isExtinct <int>, match_type <chr>,
#> #   modified <chr>
# }
```
