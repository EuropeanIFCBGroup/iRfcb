utils::globalVariables("save_class2use_to_mat")
#' Create a class2use .mat File
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
#' This function requires a python interpreter to be installed.
#' The required python packages can be installed in a virtual environment using `ifcb_py_install`.
#'
#' @return No return value. This function is called for its side effect of creating a `.mat` file.
#'
#' @seealso \code{\link{ifcb_py_install}} \code{\link{ifcb_adjust_classes}} \url{https://github.com/hsosik/ifcb-analysis}
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

  # Initialize python check
  check_python_and_module()

  # Source the Python function
  source_python(system.file("python", "save_class2use_to_mat.py", package = "iRfcb"))

  # Call the function in R
  save_class2use_to_mat(filename, classes, do_compression)
}
