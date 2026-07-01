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
#' The MAT files are read and written directly from R, producing output
#' identical to the MATLAB `ifcb-analysis` format.
#'
#' @examples
#' \dontrun{
#' ifcb_adjust_classes("data/config/class2use.mat",
#'                     "data/manual/2014/")
#' }
#'
#' @export
#'
#' @seealso \code{\link{ifcb_create_class2use}} \url{https://github.com/hsosik/ifcb-analysis}
#'
#' @references Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
ifcb_adjust_classes <- function(class2use_file, manual_folder, do_compression = TRUE) {

  # Check if file exists
  if (!file.exists(class2use_file)) {
    cli_abort("{.arg class2use_file} does not exist: {.file {class2use_file}}")
  }

  # Check if manual folder exists
  if (!dir.exists(manual_folder)) {
    cli_abort("{.arg manual_folder} does not exist: {.file {manual_folder}}")
  }

  # Ensure the class2use file has a .mat extension
  if (!grepl("\\.mat$", class2use_file)) {
    class2use_file <- paste0(class2use_file, ".mat")
  }

  # Read the class2use cell array (1 x N) from the config file
  class2use <- read_mat_v5(class2use_file)$class2use$data

  # Process every manual file (those starting with 'D') in the folder, in place
  files <- list.files(manual_folder, pattern = "^D", full.names = TRUE)

  for (file_path in files) {
    # Skip empty files
    if (file.size(file_path) == 0) {
      cli_warn("The manual file {.file {basename(file_path)}} is empty or corrupted.")
      next
    }

    manual_data <- tryCatch(read_mat_v5(file_path), error = function(e) NULL)
    if (is.null(manual_data)) {
      cli_warn("The manual file {.file {basename(file_path)}} is empty or corrupted.")
      next
    }

    # Replace the manual class list; mirror it (transposed) into the auto list
    # when that field is present, matching the ifcb-analysis behaviour
    manual_data$class2use_manual <- mat_var_cell(class2use)
    if ("class2use_auto" %in% names(manual_data)) {
      manual_data$class2use_auto <- mat_var_cell(t(class2use))
    }

    write_mat_v5(file_path, manual_data, do_compression = do_compression)
  }
}
