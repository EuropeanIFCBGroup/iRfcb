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
  details = FALSE,
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

- details:

  Logical. If `TRUE`, return a data frame with the resolved WoRMS class
  for each taxon instead of a logical vector. This is useful for
  auditing genus homonyms, i.e. diatom genera (such as `Navicula` or
  `Actinocyclus`) whose names are shared with animals and may therefore
  resolve to a non-diatom class in WoRMS. Inspect the `worms_class`
  column to spot such cases and add the affected taxa to
  `diatom_include`. Default is FALSE.

- fuzzy:

  **\[deprecated\]** The fuzzy argument is no longer available

- verbose:

  A logical indicating whether to print progress messages. Default is
  TRUE.

## Value

If `details = FALSE` (the default), a logical vector indicating whether
each cleaned taxa name belongs to the specified diatom class. If
`details = TRUE`, a
[tibble](https://tibble.tidyverse.org/reference/tibble.html) with one
row per input taxon and the columns `taxa` (the original input), `genus`
(the genus name used for matching), `worms_class` (the class resolved
from WoRMS, or `NA` if no record was found) and `is_diatom` (the logical
classification, including any `diatom_include` override).

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
