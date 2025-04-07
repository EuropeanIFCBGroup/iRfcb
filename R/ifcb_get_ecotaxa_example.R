#' Get EcoTaxa Column Names
#'
#' This function reads an example EcoTaxa metadata file included in the `iRfcb` package.
#'
#' @param example A character string specifying which example EcoTaxa metadata file to load.
#'   Options are:
#'   \describe{
#'     \item{"minimal"}{Loads a minimal example, for fully manual entry.}
#'     \item{"full_unknown"}{Loads a full featured example, with unknown objects only.}
#'     \item{"full_classified"}{Loads a full featured example, with already classified objects.}
#'     \item{"ifcb"}{(Default) Loads a full IFCB-specific dataset used for EcoTaxa submissions.}
#'   }
#'
#' @details
#' This function loads different types of EcoTaxa metadata examples
#' based on the user's need. The examples include a minimal template for manual data entry,
#' as well as fully featured datasets with or without classified objects. The default is
#' an IFCB-specific example, originating from \url{https://github.com/VirginieSonnet/IFCBdatabaseToEcotaxa}.
#' The example headers can used when submitting data from Imaging FlowCytobot (IFCB)
#' instruments to EcoTaxa at \url{https://ecotaxa.obs-vlfr.fr/}.
#'
#' @return A data frame containing EcoTaxa example metadata.
#' @export
#'
#' @examples
#' ecotaxa_example <- ifcb_get_ecotaxa_example()
#'
#' # Print the first five columns
#' dplyr::tibble(ecotaxa_example)
ifcb_get_ecotaxa_example <- function(example = "ifcb") {
  file_path <- switch(example,
                      "minimal" = "exdata/ecotaxa_table_minimum.tsv",
                      "full_unknown" = "exdata/ecotaxa_table_without_classification.tsv",
                      "full_classified" = "exdata/ecotaxa_table_with_classification.tsv",
                      "ifcb" = "exdata/example_table_ifcb.tsv",
                      stop("Invalid example type. Choose either 'minimal', 'full_unknown', 'full_classified', or 'ifcb'.")
  )

  read.table(system.file(file_path, package = "iRfcb"), sep = "\t", header = TRUE, encoding = "latin1")
}
