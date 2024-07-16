utils::globalVariables(c("scientific_name", "n_distinct", "trophic_type"))

#' @title Get Trophic Type for a List of Taxa
#' @description This function reads a file containing trophic types for various taxa (originating from SMHI),
#'              and returns the trophic type for a specified list of taxa.
#'              If there are multiple unique trophic types for a scientific name,
#'              the summarized trophic type is "NS".
#'
#' @param taxa_list A character vector of scientific names for which trophic types are to be retrieved.
#'
#' @importFrom dplyr group_by summarize filter %>% n_distinct
#' @importFrom readr read_delim
#'
#' @return A character vector of trophic types corresponding to the scientific names in \code{taxa_list}.
#'
#' @examples
#' # Example usage:
#' taxa_list <- c("Acanthoceras zachariasii",
#'                "Nodularia spumigena",
#'                "Acanthoica quattrospina",
#'                "Noctiluca",
#'                "Gymnodiniales")
#'
#' ifcb_get_trophic_type(taxa_list)
#'
#' @export
ifcb_get_trophic_type <- function(taxa_list) {
  # Read the TSV file into a data frame
  df <- read_delim(system.file("exdata/trophictype_smhi.txt", package = "iRfcb"), show_col_types = FALSE)

  # Summarize unique trophic types for each scientific_name
  summarized_df <- df %>%
    group_by(scientific_name) %>%
    summarize(trophic_type = ifelse(n_distinct(trophic_type) > 1, "NS", unique(trophic_type)),
              .groups = 'drop')

  # Create a data frame to hold the result
  result <- data.frame(scientific_name = taxa_list, trophic_type = NA, stringsAsFactors = FALSE)

  # Match scientific_name with the specified list of taxa and return the trophic type
  for (i in 1:nrow(result)) {
    match <- summarized_df %>%
      filter(scientific_name == result$scientific_name[i])
    if (nrow(match) > 0) {
      result$trophic_type[i] <- match$trophic_type
    }
  }

  return(result$trophic_type)
}
