utils::globalVariables("start_mc_adjust_classes_user_training")
#' Adjust Classifications in Manual Annotations
#'
#' This function adjusts the classifications in manual annotation files using a Python function.
#' It loads a specified class2use file and applies the adjustments to all relevant files in the
#' specified manual folder. Optionally, it can also perform compression on the output files.
#'
#' @param class2use_file A character string representing the full path to the class2use file
#'                       (should be a .mat file).
#' @param manual_folder A character string representing the path to the folder containing manual
#'                      annotation files. The function will look for files starting with 'D' in this folder.
#' @param do_compression A logical value indicating whether to apply compression to the output files.
#'                       Defaults to TRUE.
#'
#' @return None
#'
#' @details
#' This function requires a python interpreter to be installed.
#' The required python packages can be installed in a virtual environment using `ifcb_py_install`.
#'
#' @examples
#' \dontrun{
#' ifcb_adjust_classes("C:/training/config/class2use", "C:/training/manual/2014/")
#' }
#'
#' @seealso \code{\link{ifcb_py_install}} \url{https://github.com/hsosik/ifcb-analysis}
#'
#' @references Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
ifcb_adjust_classes <- function(class2use_file, manual_folder, do_compression = TRUE) {

  # Source the Python function
  source_python(system.file("python", "start_mc_adjust_classes_user_training.py", package = "iRfcb"))

  # Call the function in R
  start_mc_adjust_classes_user_training(class2use_file, manual_folder, do_compression=do_compression)
}
