#' Get Shark Column Names
#'
#' This function reads SHARK column names from a specified tab-separated values (TSV) file included in the package.
#' These columns are used for submitting IFCB data to \url{https://sharkweb.smhi.se/}.
#'
#' @return A data frame containing the SHARK column names.
#' @export
#'
#' @seealso \code{\link{ifcb_get_shark_example}}
#'
#' @examples
#' shark_colnames <- ifcb_get_shark_colnames()
#' print(shark_colnames)
ifcb_get_shark_colnames <- function() {
  shark_example <- read.table(system.file("exdata/shark_col.txt", package = "iRfcb"), sep = "\t", header = TRUE)

  # Return empty dataframe
  shark_example[0,]
}
