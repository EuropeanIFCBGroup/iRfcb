#' Edit Manual File
#'
#' This function loads a .mat file, modifies specific rows of the 'classlist' field with a new value, and saves the modified content to a new .mat file.
#'
#' @param input_file A character string specifying the path to the input .mat file.
#' @param output_file A character string specifying the path to the output .mat file.
#' @param row_numbers A numeric vector specifying the row numbers to be modified.
#' @param new_value The new value to be assigned to the specified rows.
#' @return No return value, called for side effects. Writes modified .mat file to the specified directory.
#' @examples
#' \dontrun{
#' # Edit specific rows in the manual file
#' edit_manual_file("path/to/input_file.mat", "path/to/output_file.mat", c(1, 2, 3), "new_value")
#' }
#' @import R.matlab
#' @export
edit_manual_file <- function(input_file, output_file, row_numbers, new_value) {
  # Load the MATLAB file
  mat_contents <- R.matlab::readMat(input_file)

  # Create a new list to store the modified contents
  new_mat_contents <- mat_contents

  # Modify the classlist for each row number
  classlist <- new_mat_contents$classlist
  for (row_number in row_numbers) {
    classlist[row_number, 2] <- new_value
  }

  # Update the modified classlist back into the list
  new_mat_contents$classlist <- classlist

  # Write the modified contents to a new MATLAB file
  R.matlab::writeMat(output_file, new_mat_contents)
}
