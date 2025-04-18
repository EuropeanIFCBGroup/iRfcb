% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ifcb_helper_functions.R
\name{retrieve_worms_records}
\alias{retrieve_worms_records}
\title{Retrieve WoRMS Records with Retry Mechanism}
\usage{
retrieve_worms_records(
  taxa_names,
  max_retries = 3,
  sleep_time = 10,
  marine_only = FALSE,
  verbose = TRUE
)
}
\arguments{
\item{taxa_names}{A character vector of taxa names to retrieve records for.}

\item{max_retries}{An integer specifying the maximum number of attempts to retrieve records.}

\item{sleep_time}{A numeric value indicating the number of seconds to wait between retry attempts.}

\item{marine_only}{Logical. If TRUE, restricts the search to marine taxa only. Default is FALSE.}

\item{verbose}{A logical indicating whether to print progress messages. Default is TRUE.}
}
\value{
A list of WoRMS records or NULL if the retrieval fails after the maximum number of attempts.
}
\description{
\ifelse{html}{\href{https://lifecycle.r-lib.org/articles/stages.html#deprecated}{\figure{lifecycle-deprecated.svg}{options: alt='[Deprecated]'}}}{\strong{[Deprecated]}}

This helper function was deprecated as it has been replaced by a main function: \code{ifcb_match_taxon_name()}.

This helper function attempts to retrieve WoRMS records using the provided taxa names.
It retries the operation if an error occurs, up to a specified number of attempts.
}
\keyword{internal}
