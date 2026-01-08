#' Get Shark Column Example
#'
#' This function reads a SHARK submission example from a file included in the package.
#' This format is used for submitting IFCB data to \url{https://shark.smhi.se/en/}.
#'
#' @return A data frame containing example data following the SHARK submission format.
#' @export
#'
#' @seealso \code{\link{ifcb_get_shark_colnames}}
#'
#' @examples
#' shark_example <- ifcb_get_shark_example()
#'
#' # Print example as tibble
#' print(shark_example)
ifcb_get_shark_example <- function() {
  shark_example <- read_tsv(system.file("exdata/shark_col.txt", package = "iRfcb"),
                            show_col_types = FALSE,
                            progress = FALSE)

  shark_example$DATE_TIME <- as.character(shark_example$DATE_TIME)

  shark_example
}
