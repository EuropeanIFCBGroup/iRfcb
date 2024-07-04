#' Get Shark Column Names
#'
#' This function reads shark column names from a specified tab-separated values (TSV) file included in the package.
#'
#' @return A data frame containing the shark column names.
#' @export
#'
#' @examples
#' \dontrun{
#' shark_colnames <- ifcb_get_shark_colnames()
#' print(shark_colnames)
#' }
ifcb_get_shark_colnames <- function() {
  read.table(system.file("exdata/shark_col.txt", package = "iRfcb"), sep = "\t", header = TRUE)
}
