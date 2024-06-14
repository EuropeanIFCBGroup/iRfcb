#' Replace NaN Values in Classlist
#'
#' This function loads a .mat file, replaces NaN values in a specific column of the 'classlist' field with a new value, and saves the modified content to a new .mat file.
#'
#' @param input_file A character string specifying the path to the input .mat file.
#' @param output_file A character string specifying the path to the output .mat file.
#' @param new_value The new value to replace the NaN values with.
#' @param column_index A numeric value specifying the index of the column where the replacement should occur (1-based index). Defaults to 1.
#' @return No return value, called for side effects. Writes modified .mat file to the specified directory.
#' @examples
#' \dontrun{
#' # Replace NaN values in the classlist column
#' replace_nan_in_classlist("path/to/input_file.mat", "path/to/output_file.mat", "new_value", 2)
#' }
#' @import R.matlab
#' @export
replace_nan_in_classlist <- function(input_file, output_file, new_value, column_index = 1) {
  # Load the MATLAB file
  mat_contents <- R.matlab::readMat(input_file)

  # Create a new list to store the modified contents
  new_mat_contents <- mat_contents

  # Access the classlist
  classlist <- new_mat_contents$classlist

  # Replace NaN values with new_value in the specified column
  nan_mask <- is.na(classlist[, column_index])
  classlist[nan_mask, column_index] <- new_value

  # Update the modified classlist back into the list
  new_mat_contents$classlist <- classlist

  # Write the modified contents to a new MATLAB file
  R.matlab::writeMat(output_file, new_mat_contents)
}
