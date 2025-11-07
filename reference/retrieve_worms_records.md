# Retrieve WoRMS Records with Retry Mechanism

**\[deprecated\]**

This helper function was deprecated as it has been replaced by a main
function:
[`ifcb_match_taxa_names()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_match_taxa_names.md).

This helper function attempts to retrieve WoRMS records using the
provided taxa names. It retries the operation if an error occurs, up to
a specified number of attempts.

## Usage

``` r
retrieve_worms_records(
  taxa_names,
  max_retries = 3,
  sleep_time = 10,
  marine_only = FALSE,
  verbose = TRUE
)
```

## Arguments

- taxa_names:

  A character vector of taxa names to retrieve records for.

- max_retries:

  An integer specifying the maximum number of attempts to retrieve
  records.

- sleep_time:

  A numeric value indicating the number of seconds to wait between retry
  attempts.

- marine_only:

  Logical. If TRUE, restricts the search to marine taxa only. Default is
  FALSE.

- verbose:

  A logical indicating whether to print progress messages. Default is
  TRUE.

## Value

A list of WoRMS records or NULL if the retrieval fails after the maximum
number of attempts.
