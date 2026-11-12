#' Get Shark Column Names
#'
#' This function reads SHARK column names from a specified tab-separated values (TSV) file included in the package.
#' These columns are used for submitting IFCB data to \url{https://shark.smhi.se/en/}.
#'
#' @param minimal A logical value indicating whether to load only the minimal set of column names required for data submission to SHARK. Default is FALSE.
#'
#' @return An empty data frame containing the SHARK column names.
#' @export
#'
#' @details
#' For a detailed example of a data submission, see \code{\link{ifcb_get_shark_example}}.
#'
#' \code{COUNT_UNIT} gives the unit that \code{COUNT} and \code{ABUND} are
#' reported in, for example \code{"cell"}, \code{"chain"}, \code{"colony"},
#' \code{"filament"} or \code{"coenobium"}. \code{IMAGE_COUNT} is always the
#' number of images, whatever the unit. \code{COUNT_UNIT} is optional and not
#' part of the \code{minimal} template.
#'
#' @seealso \code{\link{ifcb_get_shark_example}}
#'
#' @examples
#' shark_colnames <- ifcb_get_shark_colnames()
#' print(shark_colnames)
#'
#' shark_colnames_minimal <- ifcb_get_shark_colnames(minimal = TRUE)
#' print(shark_colnames_minimal)
ifcb_get_shark_colnames <- function(minimal = FALSE) {
  shark_example <- read_tsv(system.file("exdata/shark_col.txt", package = "iRfcb"),
                            show_col_types = FALSE,
                            progress = FALSE)

  if (minimal) {
    columns <- c("MYEAR", "STATN", "PROJ", "ORDERER", "SHIPC", "SDATE", "STIME",
                 "LATIT", "LONGI", "POSYS", "MNDEP", "MXDEP", "SLABO", "ACKR_SMP",
                 "SMTYP", "SMVOL", "IFCBNO", "SMPNO", "LATNM", "SFLAG", "TRPHY",
                 "IMAGE_VERIFICATION", "VERIFIED_BY", "COUNT", "IMAGE_COUNT", "QFLAG", "COEFF", "CLASS_F1",
                 "UNCLASSIFIED_COUNTS", "METOA", "ASSOCIATED_MEDIA", "CLASSPROG", "TRAINING_SET",
                 "ALABO", "ACKR_ANA", "ANADATE", "METDC", "CLASSIFIER_USED")

    shark_example <- dplyr::select(shark_example, dplyr::all_of(columns))
  }

  # Return empty dataframe
  shark_example[0,]
}
