#' Identify Diatoms in Taxa List
#'
#' This function takes a list of taxa names, cleans them, retrieves their
#' corresponding classification records from the World Register of Marine Species (WoRMS),
#' and checks if they belong to the specified diatom class. The function only uses the
#' first name (genus name) of each taxa for classification.
#'
#' @param taxa_list A character vector containing the list of taxa names.
#' @param diatom_class A character string specifying the class name to be identified as diatoms.
#'        Default is "Bacillariophyceae".
#'
#' @return A logical vector indicating whether each cleaned taxa name belongs to the specified diatom class.
#'
#' @examples
#' \dontrun{
#' taxa_list <- c("Nitzschia_sp", "Chaetoceros_sp", "Skeletonema_costatum", "Thalassiosira_sp")
#' ifcb_is_diatom(taxa_list)
#' }
#'
#' @importFrom dplyr %>%
#' @importFrom purrr map_chr
#' @importFrom stringr word
#' @importFrom worrms wm_records_names
#'
#' @export
#' @seealso \url{https://www.marinespecies.org/}

ifcb_is_diatom <- function(taxa_list, diatom_class = "Bacillariophyceae") {

  # Clean the taxa list
  taxa_list_clean <- taxa_list %>%
    gsub("_", " ", .) %>%
    gsub("\\bspp\\b|\\bsp\\b|\\b-like\\b|\\blike\\b|\\bsingle cell\\b|\\bchain\\b|\\bf\\b", "", .) %>%
    gsub("\\s+", " ", .) %>%
    trimws()

  # Retrieve worms records
  tryCatch({
    worms_records <- wm_records_names(word(taxa_list_clean, 1), marine_only = FALSE)
  }, error = function(err) {
    # Handle the error
    stop("Error occurred while retrieving worms records: ", conditionMessage(err))
  })

  # Extract the class from the first row of each worms_records tibble
  extract_class <- function(record) {
    if (nrow(record) == 0) {
      return(NA)
    } else {
      return(record$class[1])
    }
  }

  classes <- sapply(worms_records, extract_class)

  # Create the dataframe with taxa_list_clean and classes
  result_df <- data.frame(taxa_list_clean = taxa_list_clean, class = classes, stringsAsFactors = FALSE)

  # Check if the class is the specified diatom class
  is_diatom <- result_df$class %in% diatom_class

  return(is_diatom)
}
