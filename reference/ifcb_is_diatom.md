# Identify Diatoms in Taxa List

This function takes a list of taxa names, cleans them, retrieves their
corresponding classification records from the World Register of Marine
Species (WoRMS), and checks if they belong to the specified diatom
class. The function only uses the first name (genus name) of each taxa
for classification.

## Usage

``` r
ifcb_is_diatom(
  taxa_list,
  diatom_class = "Bacillariophyceae",
  diatom_include = NULL,
  max_retries = 3,
  sleep_time = 10,
  marine_only = FALSE,
  fuzzy = deprecated(),
  verbose = TRUE
)
```

## Arguments

- taxa_list:

  A character vector containing the list of taxa names.

- diatom_class:

  A character string or vector specifying the class name(s) to be
  identified as diatoms, according to WoRMS. Default is
  "Bacillariophyceae".

- diatom_include:

  Optional character vector of taxa (or genera) that should always be
  treated as diatoms, overriding the WoRMS-based classification. Default
  is NULL.

- max_retries:

  An integer specifying the maximum number of attempts to retrieve WoRMS
  records in case of an error. Default is 3.

- sleep_time:

  A numeric value indicating the number of seconds to wait between retry
  attempts. Default is 10 seconds.

- marine_only:

  Logical. If TRUE, restricts the search to marine taxa only. Default is
  FALSE.

- fuzzy:

  **\[deprecated\]** The fuzzy argument is no longer available

- verbose:

  A logical indicating whether to print progress messages. Default is
  TRUE.

## Value

A logical vector indicating whether each cleaned taxa name belongs to
the specified diatom class.

## See also

<https://www.marinespecies.org/>

## Examples

``` r
# \donttest{
# Example taxa
taxa_list <- c("Nitzschia_sp", "Chaetoceros_sp", "Dinophysis_norvegica", "Thalassiosira_sp")

res <- ifcb_is_diatom(taxa_list)
print(res)
#> [1]  TRUE  TRUE FALSE  TRUE
# }
```
