#' Create a class2use `.mat` File
#'
#' This function creates a `.mat` file containing a character vector of class names.
#' A class2use file can be used for manual annotation using the code in the `ifcb-analysis`
#' repository (Sosik and Olson 2007).
#'
#' @param classes A character vector of class names to be saved in the `.mat` file.
#' @param filename A string specifying the output file path (with `.mat` extension).
#' @param do_compression A logical value indicating whether to compress the `.mat` file. Defaults to `TRUE`.
#'
#' @export
#'
#' @details
#' The `.mat` file is written directly from R, producing output identical to
#' the MATLAB `ifcb-analysis` format. No Python installation is required.
#'
#' @return No return value. This function is called for its side effect of creating a `.mat` file.
#'
#' @seealso \code{\link{ifcb_adjust_classes}} \url{https://github.com/hsosik/ifcb-analysis}
#'
#' @references Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
#'
#' @examples
#' \dontrun{
#' # Example usage:
#' classes <- c("unclassified", "Dinobryon_spp", "Helicostomella_spp")
#'
#' ifcb_create_class2use(classes, "class2use_output.mat", do_compression = TRUE)
#' }
ifcb_create_class2use <- function(classes, filename, do_compression = TRUE) {

  # Check if the output directory exists, if not create it
  if (!dir.exists(dirname(filename))) {
    dir.create(dirname(filename), recursive = TRUE)
  }

  # Write the class2use variable as a 1 x N cell array of strings
  write_mat_v5(
    filename,
    list(class2use = mat_var_cell(matrix(as.character(classes), nrow = 1))),
    do_compression = do_compression
  )
}
