library(R.matlab)

get_class2use <- function(class2use_file) {
  # Read class information from MAT files
  class2use <- readMat(class2use_file)

  # Extract classes
  classes <- unlist(class2use$class2use)

  return(classes)
}