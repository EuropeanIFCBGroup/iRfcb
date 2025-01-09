utils::globalVariables("create_and_save_mat_structure")
#' Create an Empty Manual Classification MAT File
#'
#' Generates a MAT file for IFCB data with an empty manual classification structure using a specified number of ROIs,
#' class names, and saves it to a specified output file. This function utilizes a Python script for creating the structure.
#'
#' @param roi_length Integer. The number of rows in the class list (number of ROIs).
#' @param class2use Character vector. The names of the classes to include in the `class2use_manual` field of the MAT file.
#' @param output_file Character. The path where the output MAT file will be saved.
#' @param unclassified_id Integer. The value to use in the second column of the class list. Default is 1.
#' @param do_compression A logical value indicating whether to compress the .mat file. Default is TRUE.
#'
#' @details
#' This function requires a python interpreter to be installed. The required python packages can be installed in a virtual environment using `ifcb_py_install`.
#'
#' @return No return value. This function is called for its side effects.
#' The created MAT file is saved at the specified `output_file` location.
#'
#' @examples
#' \dontrun{
#' # Initialize a python session if not already set up
#' ifcb_py_install()
#'
#' # Create a MAT file with 100 ROIs, using a vector of class names, and save it to "output.mat"
#' ifcb_create_empty_manual_file(roi_length = 100,
#'                               class2use = c("unclassified", "Aphanizomenon_spp"),
#'                               output_file = "output.mat")
#'
#' # Create a MAT file with a different unclassified_id
#' ifcb_create_empty_manual_file(roi_length = 100,
#'                               class2use = c("unclassified", "Aphanizomenon_spp"),
#'                               output_file = "output.mat",
#'                               unclassified_id = 999)
#' }
#'
#' @export
ifcb_create_empty_manual_file <- function(roi_length, class2use, output_file, unclassified_id = 1, do_compression = TRUE) {

  # Initialize python check
  check_python_and_module()

  # Import the Python function
  source_python(system.file("python", "create_manual_mat.py", package = "iRfcb"))

  # Create the MAT file
  create_and_save_mat_structure(as.integer(roi_length),
                                as.character(class2use),
                                output_file,
                                as.integer(unclassified_id),
                                do_compression)
}
