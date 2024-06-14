library(raveio)

get_class2use_from_classifer <- function(class_file) {
  # Read class information from MAT files
  class2use <- read_mat(class_file)
  
  # Extract classes
  classes <- unlist(classes$classes)
  
  return(classes)
}