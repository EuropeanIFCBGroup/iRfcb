utils::globalVariables(c("scientific_name", "trophic_type"))

#' @title Get Trophic Type for a List of Plankton Taxa
#' @description This function matches a specified list of taxa with a summarized list of trophic types
#'              for various plankton taxa from Northern Europe (data sourced from `SMHI Trophic Type`).
#'
#' @param taxa_list A character vector of scientific names for which trophic types are to be retrieved.
#' @param print_complete_list Logical, if TRUE, prints the complete list of summarized trophic types.
#'
#' @details
#' If there are multiple trophic types for a scientific name (i.e. AU and HT size classes),
#' the summarized trophic type is "NS".
#'
#' @return A character vector of trophic types corresponding to the scientific names in \code{taxa_list},
#' or a data frame containing all taxa and trophic types available in the `SMHI Trophic Type` list.
#' The available trophic types are autotrophic (AU), heterotrophic (HT), mixotrophic (MX) or not specified (NS).
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
ifcb_get_trophic_type <- function(taxa_list = NULL, print_complete_list = FALSE) {

  # Input validation using base R
  if (!is.null(taxa_list) && !is.character(taxa_list)) {
    stop("Error: taxa_list must be a character vector.")
  }

  if (!is.logical(print_complete_list)) {
    stop("Error: print_complete_list must be a logical value.")
  }

  if (!is.null(taxa_list) && print_complete_list) {
    warning("Both taxa_list and print_complete_list are provided. Only the taxa_list results will be returned.")
  }

  # Create a temp dir
  exdir <- tempdir()

  # Unzip trophic_type list in tempdir
  unzip(system.file("exdata", "trophictype_smhi.zip", package = "iRfcb"), exdir = exdir)

  # Read the TSV file into a data frame
  df <- read_delim(file.path(exdir, "trophictype_smhi.txt"), show_col_types = FALSE)

  # Summarize unique trophic types for each scientific_name
  summarized_df <- df %>%
    group_by(scientific_name) %>%
    summarize(trophic_type = ifelse(n_distinct(trophic_type) > 1, "NS", unique(trophic_type)),
              .groups = 'drop')

  if (!is.null(taxa_list)) {

    result <- data.frame(scientific_name = taxa_list, trophic_type = NA)

    # Match scientific_name with the specified list of taxa and return the trophic type
    for (i in seq_len(nrow(result))) {
      match <- summarized_df %>%
        filter(scientific_name == result$scientific_name[i])
      if (nrow(match) > 0) {
        result$trophic_type[i] <- match$trophic_type
      }
    }
    output <- result$trophic_type

  } else if (print_complete_list) {
    output <- summarized_df
  } else {
    stop("Error: No valid input provided. Please specify either taxa_list or set print_complete_list to TRUE.")
  }

  return(output)
}
