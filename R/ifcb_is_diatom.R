#' Identify Diatoms in Taxa List
#'
#' This function takes a list of taxa names, cleans them, retrieves their
#' corresponding classification records from the World Register of Marine Species (WoRMS),
#' and checks if they belong to the specified diatom class. The function only uses the
#' first name (genus name) of each taxa for classification.
#'
#' @param taxa_list A character vector containing the list of taxa names.
#' @param diatom_class A character string or vector specifying the class name(s) to be identified as diatoms, according to WoRMS.
#'        Default is "Bacillariophyceae".
#' @param diatom_include Optional character vector of taxa (or genera) that should
#'        always be treated as diatoms, overriding the WoRMS-based classification.
#'        Default is NULL.
#' @param max_retries An integer specifying the maximum number of attempts to retrieve WoRMS records in case of an error.
#'        Default is 3.
#' @param sleep_time A numeric value indicating the number of seconds to wait between retry attempts.
#'        Default is 10 seconds.
#' @param marine_only Logical. If TRUE, restricts the search to marine taxa only. Default is FALSE.
#' @param verbose A logical indicating whether to print progress messages. Default is TRUE.
#' @param fuzzy
#'    `r lifecycle::badge("deprecated")`
#'    The fuzzy argument is no longer available
#'
#' @return A logical vector indicating whether each cleaned taxa name belongs to the specified diatom class.
#'
#' @examples
#' \donttest{
#' # Example taxa
#' taxa_list <- c("Nitzschia_sp", "Chaetoceros_sp", "Dinophysis_norvegica", "Thalassiosira_sp")
#'
#' res <- ifcb_is_diatom(taxa_list)
#' print(res)
#' }
#'
#' @export
#' @seealso \url{https://www.marinespecies.org/}
ifcb_is_diatom <- function(taxa_list, diatom_class = "Bacillariophyceae", diatom_include = NULL,
                           max_retries = 3, sleep_time = 10, marine_only = FALSE,
                           fuzzy = deprecated(), verbose = TRUE) {

  # Warn the user if fuzzy is used
  if (lifecycle::is_present(fuzzy)) {
    # Signal the deprecation to the user
    deprecate_warn("0.4.2", "iRfcb::ifcb_is_diatom(fuzzy = )")
  }

  # Clean the taxa list
  taxa_list_clean <- taxa_list %>%
    gsub("_", " ", .) %>%
    gsub("\\bspp\\b|\\bsp\\b|\\b-like\\b|\\blike\\b|\\bsingle cell\\b|\\bchain\\b|\\bf\\b", "", .) %>%
    gsub("\\s+", " ", .) %>%
    trimws()

  # Retrieve WoRMS records
  worms_data <- ifcb_match_taxa_names(taxa_names = word(taxa_list_clean, 1),
                                      max_retries = max_retries,
                                      sleep_time = sleep_time,
                                      marine_only = marine_only,
                                      fuzzy = fuzzy,
                                      return_list = FALSE,
                                      verbose = verbose)

  result_df <- data.frame(taxa_list_clean = taxa_list_clean, class = worms_data$class)

  # Check if the class is the specified diatom class
  is_diatom <- result_df$class %in% diatom_class

  # Override diatom classification if diatom_include is provided
  if (!is.null(diatom_include)) {

    taxa_genus <- word(taxa_list_clean, 1)
    matched <- taxa_genus %in% diatom_include

    is_diatom[matched] <- TRUE
  }

  return(is_diatom)
}
