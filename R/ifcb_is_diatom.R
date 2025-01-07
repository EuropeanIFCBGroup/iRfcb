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
#' @param max_retries An integer specifying the maximum number of attempts to retrieve WoRMS records in case of an error.
#'        Default is 3.
#' @param sleep_time A numeric value indicating the number of seconds to wait between retry attempts.
#'        Default is 10 seconds.
#' @param marine_only Logical. If TRUE, restricts the search to marine taxa only. Default is FALSE.
#' @param fuzzy A logical value indicating whether to search using a fuzzy search pattern. Default is TRUE.
#' @param verbose A logical indicating whether to print progress messages. Default is TRUE.
#'
#' @return A logical vector indicating whether each cleaned taxa name belongs to the specified diatom class.
#'
#' @examples
#' \dontrun{
#' taxa_list <- c("Nitzschia_sp", "Chaetoceros_sp", "Dinophysis_norvegica", "Thalassiosira_sp")
#' ifcb_is_diatom(taxa_list)
#' }
#'
#' @export
#' @seealso \url{https://www.marinespecies.org/}
ifcb_is_diatom <- function(taxa_list, diatom_class = "Bacillariophyceae", max_retries = 3, sleep_time = 10, marine_only = FALSE, fuzzy = TRUE, verbose = TRUE) {

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
                                      return_list = TRUE,
                                      verbose = verbose)

  # Extract classes with error handling for missing data
  classes <- sapply(worms_data, function(record) {
    if (!is.null(record)) {
      extract_class(record)
    } else {
      NA
    }
  })

  # Create the dataframe with taxa_list_clean and classes
  result_df <- data.frame(taxa_list_clean = taxa_list_clean, class = classes, stringsAsFactors = FALSE)

  # Check if the class is the specified diatom class
  is_diatom <- result_df$class %in% diatom_class

  return(is_diatom)
}
