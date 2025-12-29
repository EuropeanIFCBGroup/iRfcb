utils::globalVariables("start_mc_adjust_classes_user_training")
#' Adjust Classifications in Manual Annotations
#'
#' This function adjusts the classifications in manual annotation files based on a class2use file.
#' It loads a specified class2use file and applies the adjustments to all relevant files in the
#' specified manual folder. Optionally, it can also perform compression on the output files.
#' This is the R equivalent function of `start_mc_adjust_classes_user_training` from the
#' `ifcb-analysis` repository (Sosik and Olson 2007).
#'
#' @param class2use_file A character string representing the full path to the class2use file
#'                       (should be a .mat file).
#' @param manual_folder A character string representing the path to the folder containing manual
#'                      annotation files. The function will look for files starting with 'D' in this folder.
#' @param do_compression A logical value indicating whether to apply compression to the output files.
#'                       Defaults to TRUE.
#' @return None
#'
#' @details
#' Python must be installed to use this function. The required python packages can be installed in a virtual environment using `ifcb_py_install()`.
#'
#' @examples
#' \dontrun{
#' # Initialize a python session if not already set up
#' ifcb_py_install()
#'
#' ifcb_adjust_classes("data/config/class2use.mat",
#'                     "data/manual/2014/")
#' }
#'
#' @export
#'
#' @seealso \code{\link{ifcb_py_install}} \code{\link{ifcb_create_class2use}} \url{https://github.com/hsosik/ifcb-analysis}
#'
#' @references Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
ifcb_adjust_classes <- function(class2use_file, manual_folder, do_compression = TRUE) {

  # Check if file exists
  if (!file.exists(class2use_file)) {
    stop(paste("File does not exist:", class2use_file))
  }

  # Check if manual folder exists
  if (!dir.exists(manual_folder)) {
    stop(paste("Manual folder does not exist:", manual_folder))
  }

  # Initialize python check
  check_python_and_module()

  # Source the Python function
  source_python(system.file("python", "start_mc_adjust_classes_user_training.py", package = "iRfcb"))

  # Remove .mat extension
  class2use_file <- gsub(".mat", "", class2use_file)

  # Call the function in R
  start_mc_adjust_classes_user_training(class2use_file, manual_folder, do_compression=do_compression)
}
