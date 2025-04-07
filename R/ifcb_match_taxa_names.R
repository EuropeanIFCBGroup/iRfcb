#' Retrieve WoRMS Records with Retry Mechanism
#'
#' This function attempts to retrieve WoRMS records using the provided taxa names.
#' It retries the operation if an error occurs, up to a specified number of attempts.
#'
#' @param taxa_names A character vector of taxa names to retrieve records for.
#' @param best_match_only A logical value indicating whether to automatically select the first match and return a single match. Default is TRUE.
#' @param max_retries An integer specifying the maximum number of attempts to retrieve records.
#' @param sleep_time A numeric value indicating the number of seconds to wait between retry attempts.
#' @param marine_only Logical. If TRUE, restricts the search to marine taxa only. Default is FALSE.
#' @param return_list A logical value indicating whether to to return the output as a list. Default is FALSE, where the result is returned as a dataframe.
#' @param verbose A logical indicating whether to print progress messages. Default is TRUE.
#' @param fuzzy
#'    `r lifecycle::badge("deprecated")`
#'    The fuzzy argument is no longer available
#'
#' @return A data frame (or list if return_list is TRUE) of WoRMS records or NULL if the retrieval fails after the maximum number of attempts.
#'
#' @examples
#' \dontrun{
#' # Example: Retrieve WoRMS records for a list of taxa names
#' taxa <- c("Calanus finmarchicus", "Thalassiosira pseudonana", "Phaeodactylum tricornutum")
#'
#' # Call the function
#' records <- ifcb_match_taxa_names(taxa_names = taxa,
#'                                  max_retries = 3,
#'                                  sleep_time = 5,
#'                                  marine_only = TRUE,
#'                                  verbose = TRUE)
#'
#' print(records)
#' }
#'
#' @export
ifcb_match_taxa_names <- function(taxa_names, best_match_only = TRUE, max_retries = 3, sleep_time = 10,
                                  marine_only = FALSE, return_list = FALSE, verbose = TRUE, fuzzy = deprecated()) {

  # Warn the user if fuzzy is used
  if (lifecycle::is_present(fuzzy)) {
    # Signal the deprecation to the user
    deprecate_warn("0.4.2", "iRfcb::ifcb_match_taxa_names(fuzzy = )")
  }

  attempt <- 1
  success <- FALSE
  worms_records <- NULL
  no_content_messages <- NULL

  while (attempt <= max_retries && !success) {
    tryCatch({
      # Retrieve records for all taxa at once
      worms_records <- wm_records_names(taxa_names, marine_only = marine_only)

      # Ensure all taxa are represented, filling missing responses with NA
      worms_records <- lapply(seq_along(taxa_names), function(i) {
        if (length(worms_records[[i]]) == 0) {
          data.frame(name = taxa_names[i], status = "no content", AphiaID = NA, rank = NA, valid_name = NA, stringsAsFactors = FALSE)
        } else {
          # Select only the best match if requested
          match_data <- worms_records[[i]]
          if (best_match_only) {
            match_data <- match_data[1, ]  # Select the first row (alternative: use a ranking method)
          }
          data.frame(name = taxa_names[i], match_data)
        }
      })

      worms_records <- bind_rows(worms_records)

      success <- TRUE  # Mark success to exit loop
    }, error = function(err) {
      error_message <- conditionMessage(err)

      # Handle specific errors
      if (grepl("204", error_message)) {
        no_content_messages <<- c(no_content_messages, "No WoRMS content for some taxa.")
        worms_records <<- data.frame(name = taxa_names, status = "no content", AphiaID = NA, class = NA, stringsAsFactors = FALSE)
        success <<- TRUE  # Prevent further retries
      } else if (grepl("404", error_message)) {
        no_content_messages <<- c(no_content_messages, "WoRMS record not found for some taxa.")
        worms_records <<- data.frame(name = taxa_names, status = "not found", AphiaID = NA, class = NA, stringsAsFactors = FALSE)
        success <<- TRUE  # Prevent further retries
      } else if (attempt == max_retries) {
        stop("Error retrieving WoRMS records after ", max_retries, " attempts: ", error_message)
      } else {
        Sys.sleep(sleep_time)
      }
    })

    attempt <- attempt + 1
  }

  # If still NULL after retries, insert NA
  if (is.null(worms_records)) {
    worms_records <- data.frame(name = taxa_names, status = "Failed", AphiaID = NA, class = NA, stringsAsFactors = FALSE)
  }

  if (verbose && length(no_content_messages) > 0) {
    cat(paste(no_content_messages, collapse = "\n"), "\n")
  }

  if (return_list) {
    split(worms_records, worms_records$name)
  } else {
    worms_records
  }
}
