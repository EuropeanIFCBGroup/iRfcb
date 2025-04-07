#' Merge IFCB Manual Classification Data
#'
#' This function merges two sets of manual classification data by combining
#' and aligning class labels from a base set and an additional set of classifications.
#' The merged `.mat` data can be used with the code in the `ifcb-analysis` repository (Sosik and Olson 2007).
#'
#' @param class2use_file_base Character. Path to the `class2use` file of the base manual classifications.
#' The base set contains the original manual classifications list that form the foundation for merging.
#' @param class2use_file_additions Character. Path to the `class2use` file of the additions manual classifications.
#' The additions set contains additional classifications that need to be merged with the base set.
#' Class labels from the `class2use_file_additions` that are not already included in the `class2use_file_base` will be added to generate the `class2use_file_output`.
#' @param class2use_file_output Character. Path where the merged `class2use` file will be saved.
#' If `NULL`, the merged file will be stored in the same directory as `class2use_file_base`. Default is `NULL`.
#' @param manual_folder_base Character. Path to the folder containing the base set of manual classification `.mat` files.
#' @param manual_folder_additions Character. Path to the folder containing the additions set of manual classification `.mat` files.
#' @param manual_folder_output Character. Path to the output folder where the merged classification files will be stored.
#' @param do_compression A logical value indicating whether to compress the `.mat` file. Defaults to `TRUE`.
#' @param temp_index_offset Numeric. A large integer used to generate temporary indices during the merge process. Default is 50000.
#' @param skip_class Character. A vector of class names to skip from the `class2use_file_additions` during the merge process. Default is `NULL`.
#' @param quiet Logical. If `TRUE`, suppresses output messages. Default is `FALSE`.
#'
#' @return No return value. Outputs the combined `class2use` file in the same folder as `class2use_file_base` is located or at a user-specified location,
#'  and merged `.mat` files into the output folder.
#'
#' @details
#' Python must be installed to use this function. The required python packages can be installed in a virtual environment using `ifcb_py_install()`.
#'
#' The **base** set consists of the original classifications that are used as a reference for the merging process.
#' The **additions** set contains the additional classifications that need to be merged with the base set.
#' When merging, unique class names from the additions set that are not present in the base set are appended.
#'
#' The function works by aligning the class labels from the additions set with those in the base set,
#' handling conflicts by using a temporary index system. It copies `.mat` files from both the base and
#' additions folders into the output folder, while adjusting indices and and class names for the additions.
#'
#' Note that the maximum limit for `uint16` is 65,535, so ensure that `temp_index_offset` remains below this value.
#'
#' @seealso \code{\link{ifcb_py_install}} \url{https://github.com/hsosik/ifcb-analysis}
#' @references Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
#'
#' @examples
#' \dontrun{
#' ifcb_merge_manual("path/to/class2use_base.mat", "path/to/class2use_additions.mat",
#'                   "path/to/class2use_combined.mat", "path/to/manual/base_folder",
#'                   "path/to/manual/additions_folder", "path/to/manual/output_folder",
#'                   do_compression = TRUE, temp_index_offset = 50000, quiet = FALSE)
#' }
#'
#' @export
ifcb_merge_manual <- function(class2use_file_base, class2use_file_additions,
                              class2use_file_output = NULL, manual_folder_base,
                              manual_folder_additions, manual_folder_output,
                              do_compression = TRUE, temp_index_offset = 50000,
                              skip_class = NULL, quiet = FALSE) {

  # Initialize python check
  check_python_and_module()

  # Check if base and additions files exist
  if (!file.exists(class2use_file_base) || !file.exists(class2use_file_additions)) {
    stop("Base or additions class2use file does not exist.")
  }

  # Check if base and additions files exist
  if (!dir.exists(manual_folder_base) || !dir.exists(manual_folder_additions)) {
    stop("Base or additions manual folder does not exist.")
  }

  # Get base and additional class names
  class2use_base <- as.character(ifcb_get_mat_variable(class2use_file_base))
  class2use_additions <- as.character(ifcb_get_mat_variable(class2use_file_additions))

  # Remove classes to skip
  if(!is.null(skip_class)) {
    class2use_additions <- class2use_additions[!class2use_additions %in% skip_class]
  }

  # Combine vectors, only add unique elements from additions
  class2use_combined <- unique(c(class2use_base, class2use_additions))

  # Create dataframe with index translations
  translation_df <- data.frame(
    rownumber = seq_along(class2use_combined),
    class2use_combined = class2use_combined,
    index_in_base = match(class2use_combined, class2use_base),
    index_in_additions = match(class2use_combined, class2use_additions)
  )

  # Create temporary placeholder indices
  translation_df$temp_index <- translation_df$index_in_additions + temp_index_offset

  if (is.null(class2use_file_output)) {
    # Create file path for the combined class2use file
    class2use_file_output <- file.path(dirname(class2use_file_base),
                                       paste0("class2use_", basename(manual_folder_output), ".mat")
                                       )
  }

  # Create dir for storing the new class2use file
  if (!dir.exists(dirname(class2use_file_output))) {
    dir.create(dirname(class2use_file_output), recursive = TRUE)
  }

  # Create new class2use file
  ifcb_create_class2use(class2use_combined, class2use_file_output, do_compression)

  if (!quiet) {
    message("class2use file stored in ", class2use_file_output)
  }

  # Get base and additions files
  base_files <- list.files(manual_folder_base, pattern = "\\.mat$", full.names = TRUE, recursive = FALSE)
  additions_files <- list.files(manual_folder_additions, pattern = "\\.mat$", full.names = TRUE, recursive = FALSE)

  if (length(base_files) == 0) {
    stop("No .mat files found in manual_folder_base")
  }

  if (length(additions_files) == 0) {
    stop("No .mat files found in manual_folder_additions")
  }

  # Create the combined folder if it doesn't exist
  if (!dir.exists(manual_folder_output)) {
    dir.create(manual_folder_output, recursive = TRUE)
  }

  # Copy the addition files with logging
  copied_additions <- file.copy(additions_files, manual_folder_output, overwrite = TRUE)
  if (!quiet) {
    message("Copied ", sum(copied_additions), " addition files to ", manual_folder_output)
  }

  # Filter translation data
  addition_translations <- translation_df[!is.na(translation_df$index_in_additions) & translation_df$index_in_additions != translation_df$rownumber, ]

  if (!quiet) {
    # Message indicating the number of indices being replaced
    message(paste0("Replacing ", nrow(addition_translations), " class indices with temporary placeholders..."))
  }

  # Set up the progress bar
  if (!quiet & nrow(addition_translations) > 0) {pb <- txtProgressBar(min = 0, max = nrow(addition_translations), style = 3)}

  # Replace index with placeholder index
  for (i in seq_len(nrow(addition_translations))) {
    # Update progress bar
    if (!quiet & nrow(addition_translations) > 0) {setTxtProgressBar(pb, i)}

    ifcb_replace_mat_values(
      manual_folder_output, manual_folder_output,
      addition_translations$index_in_additions[i],
      addition_translations$temp_index[i],
      do_compression = do_compression
    )
  }

  # Close the progress bar
  if (!quiet & nrow(addition_translations) > 0) {
    close(pb)
  }

  if (!quiet) {
    # Message indicating the number of indices being replaced
    message(paste0("Replacing ", nrow(addition_translations), " class indices with updated values..."))
  }

  # Set up the progress bar
  if (!quiet & nrow(addition_translations) > 0) {pb2 <- txtProgressBar(min = 0, max = nrow(addition_translations), style = 3)}

  # Replace placeholder index with rownumber
  for (i in seq_len(nrow(addition_translations))) {
    # Update progress bar
    if (!quiet & nrow(addition_translations) > 0) {setTxtProgressBar(pb2, i)}

    ifcb_replace_mat_values(
      manual_folder_output, manual_folder_output,
      addition_translations$temp_index[i],
      addition_translations$rownumber[i],
      do_compression = do_compression
    )
  }

  # Close the progress bar
  if (!quiet & nrow(addition_translations) > 0) {
    close(pb2)
  }

  # Copy the base files with logging
  copied_base <- file.copy(base_files, manual_folder_output, overwrite = TRUE)

  if (!quiet) {
    message("Copied ", sum(copied_base), " base files to ", manual_folder_output)
  }

  # Message indicating the number of indices being replaced
  if (!quiet) {
    message(paste0("Adjusting class names in ", sum(copied_additions) + sum(copied_base), " files..."))
  }

  # Adjust the class names for all files
  ifcb_adjust_classes(class2use_file_output, manual_folder_output, do_compression = do_compression)
}
