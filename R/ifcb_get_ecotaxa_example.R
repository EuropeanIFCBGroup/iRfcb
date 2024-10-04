#' Get Ecotaxa Column Names
#'
#' This function reads an example Ecotaxa metadata file included in the `iRfcb` package.
#' The example file originates from \url{https://github.com/VirginieSonnet/IFCBdatabaseToEcotaxa}
#' These columns are used for submitting IFCB data to \url{https://ecotaxa.obs-vlfr.fr/}.
#'
#' @return A data frame containing Ecotaxa example metadata.
#' @export
#'
#' @examples
#' \dontrun{
#' ecotaxa_example <- ifcb_get_ecotaxa_example()
#' print(ecotaxa_example)
#' }
ifcb_get_ecotaxa_example <- function() {
  read.table(system.file("exdata/example_columns_ecotaxa.tsv", package = "iRfcb"), sep = "\t", header = TRUE)
}
