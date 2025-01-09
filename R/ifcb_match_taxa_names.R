#' Retrieve WoRMS Records with Retry Mechanism
#'
#' This function attempts to retrieve WoRMS records using the provided taxa names.
#' It retries the operation if an error occurs, up to a specified number of attempts.
#'
#' @param taxa_names A character vector of taxa names to retrieve records for.
#' @param fuzzy A logical value indicating whether to search using a fuzzy search pattern. Default is TRUE.
#' @param best_match_only A logical value indicating whether to automatically select the first match and return a single match. Default is TRUE.
#' @param max_retries An integer specifying the maximum number of attempts to retrieve records.
#' @param sleep_time A numeric value indicating the number of seconds to wait between retry attempts.
#' @param marine_only Logical. If TRUE, restricts the search to marine taxa only. Default is FALSE.
#' @param return_list A logical value indicating whether to to return the output as a list. Default is FALSE, where the result is returned as a dataframe.
#' @param verbose A logical indicating whether to print progress messages. Default is TRUE.
#'
#' @return A data frame (or list if return_list is TRUE) of WoRMS records or NULL if the retrieval fails after the maximum number of attempts.
#'
#' @examples
#' \dontrun{
#' # Example: Retrieve WoRMS records for a list of taxa names
#' taxa <- c("Calanus finmarchicus", "Thalassiosira pseudonana", "Phaeodactylum tricornutum")
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
ifcb_match_taxa_names <- function(taxa_names, fuzzy = TRUE, best_match_only = TRUE, max_retries = 3,
                                  sleep_time = 10, marine_only = FALSE, return_list = FALSE, verbose = TRUE) {

  worms_records <- list()  # Initialize an empty list to collect records for each name

  # Set up progress bar
  if (verbose) {pb <- txtProgressBar(min = 0, max = length(taxa_names), style = 3)}

  no_content_messages <- NULL  # Store "No content" messages

  for (i in seq_along(taxa_names)) {
    attempt <- 1
    worms_record <- NULL  # Reset for the current taxon name
    success <- FALSE      # Track whether retrieval was successful

    # Update progress bar
    if (verbose) {setTxtProgressBar(pb, i)}

    while (attempt <= max_retries && !success) {
      tryCatch({
        worms_record <- data.frame(
          name = taxa_names[i],
          wm_records_name(taxa_names[i],
                          fuzzy = fuzzy,
                          marine_only = marine_only)
        )

        if (best_match_only) {
          worms_record <- worms_record[1,]
        }

        if (!is.null(worms_record)) {
          success <- TRUE  # Mark success to exit loop
        }
      }, error = function(err) {
        error_message <- conditionMessage(err)

        # Check for 204 "No Content" or 404 "Not Found" response
        if (grepl("204", error_message)) {
          no_content_messages <<- c(no_content_messages,
                                    paste0("No WoRMS content for '", taxa_names[i], "'"))
          worms_record <<- data.frame(name = taxa_names[i], status = "no content", AphiaID = NA, class = NA, stringsAsFactors = FALSE)
          success <<- TRUE  # Mark success to prevent further retries
        } else if (grepl("404", error_message)) {
          no_content_messages <<- c(no_content_messages,
                                    paste0("WoRMS record not found for '", taxa_names[i], "'"))
          worms_record <<- data.frame(name = taxa_names[i], status = "not found", AphiaID = NA, class = NA, stringsAsFactors = FALSE)
          success <<- TRUE  # Mark success to prevent further retries
        } else if (attempt == max_retries) {
          stop("Error occurred while retrieving WoRMS record for '", taxa_names[i],
               "' after ", max_retries, " attempts: ", error_message)
        } else {
          Sys.sleep(sleep_time)
        }
      })

      attempt <- attempt + 1
    }

    # If still NULL after retries, insert NA
    if (is.null(worms_record)) {
      worms_record <- data.frame(name = taxa_names[i], status = "Failed", AphiaID = NA, class = NA, stringsAsFactors = FALSE)
    }

    if (return_list) {
      worms_records <- append(worms_records, list(worms_record))
    } else {
      worms_records <- bind_rows(worms_records, worms_record)
    }
  }

  if (verbose) {close(pb)}

  # Print all "No content" messages after progress bar finishes
  if (verbose && length(no_content_messages) > 0) {
    cat(paste(no_content_messages, collapse = "\n"), "\n")
  }

  worms_records
}
