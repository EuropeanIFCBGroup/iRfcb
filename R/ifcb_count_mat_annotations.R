#' Count IFCB Annotations from .mat Files
#'
#' This function processes .mat files in a specified folder to count and summarize 
#' the annotations for each class based on the class2use information provided in a file.
#'
#' @param manual_folder A character string specifying the path to the folder containing .mat files.
#' @param class2use_file A character string specifying the path to the file containing the class2use variable.
#' @param skip_class A numeric vector of class IDs to be excluded from the count. Default is NULL.
#'
#' @return A data frame with the total count of images per class.
#' @export
#'
#' @examples
#' \dontrun{
#' result <- ifcb_count_mat_annotations("path/to/manual_folder", "path/to/class2use_file", skip_class = c(99, 100))
#' }
ifcb_count_mat_annotations <- function(manual_folder, class2use_file, skip_class = NULL) {
  # List .mat files in the specified folder
  mat_files <- list.files(manual_folder, pattern = "\\.mat$", full.names = TRUE, recursive = FALSE)
  
  # Get the class2use variable from the specified file
  class2use <- ifcb_get_mat_variable(class2use_file)
  
  # Create a lookup table from class2use
  lookup_table <- data.frame(
    manual = seq_along(class2use),
    name = class2use
  )
  
  # Initialize an empty data frame to accumulate the results
  total_sum <- data.frame(class = character(), n = integer())
  
  for (file in mat_files) {
    # Read the taxa list from the file
    taxa_list <- as.data.frame(readMat(file)$classlist)  # Assuming readMat is used to read .mat files
    
    # Assign names to the columns in taxa_list
    names(taxa_list) <- unlist(readMat(file)$list.titles)
    
    # Remove the skip class and NA values from the taxa list
    taxa_list <- taxa_list[!taxa_list$manual %in% skip_class & !is.na(taxa_list$manual), ]
    
    # Replace the numbers in taxa_list$manual with the corresponding names using a lookup table
    taxa_list <- merge(taxa_list, lookup_table, by = "manual", all.x = TRUE)
    taxa_list$class <- ifelse(is.na(taxa_list$name), as.character(taxa_list$manual), taxa_list$name)
    taxa_list$name <- NULL
    
    # Summarize the number of images by class
    sample_sum <- count(taxa_list, class)
    
    # Accumulate the results into total_sum
    total_sum <- rbind(total_sum, sample_sum)
  }
  
  # Combine and summarize results
  total_sum <- total_sum %>%
    group_by(class) %>%
    summarise(n = sum(n, na.rm = TRUE))
  
  return(total_sum)
}
