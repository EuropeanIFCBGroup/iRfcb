utils::globalVariables(c("name", "manual"))
#' Extract Annotated Images from IFCB Data
#'
#' This function extracts labeled images from IFCB (Imaging FlowCytobot) data,
#' annotated using the MATLAB code from the `ifcb-analysis` repository (Sosik and Olson 2007).
#' It reads manually classified data, maps class indices to class names, and extracts
#' the corresponding Region of Interest (ROI) images, saving them to the specified directory.
#'
#' @param manual_folder A character string specifying the path to the directory containing the manually classified .mat files.
#' @param class2use_file A character string specifying the path to the file containing class names.
#' @param roi_folders A character vector specifying one or more directories containing the ROI files.
#' @param out_folder A character string specifying the output directory where the extracted images will be saved.
#' @param skip_class A numeric vector of class IDs or a character vector of class names to be excluded from the count. Default is NULL.
#' @param verbose A logical value indicating whether to print progress messages. Default is TRUE.
#' @param manual_recursive Logical. If TRUE, the function will search for MATLAB files recursively within the `manual_folder`. Default is FALSE.
#' @param roi_recursive Logical. If TRUE, the function will search for data files recursively within the `roi_folder` (if provided). Default is TRUE.
#' @param overwrite A logical value indicating whether to overwrite existing PNG files. Default is FALSE.
#' @param use_python Logical. If `TRUE`, attempts to read the `.mat` file using a Python-based method. Default is `FALSE`.
#' @param roi_folder
#'    `r lifecycle::badge("deprecated")`
#'    Use `roi_folders` instead.
#'
#' @return None. The function saves the extracted PNG images to the specified output directory.
#'
#' @details
#' If `use_python = TRUE`, the function tries to read the `.mat` file using `ifcb_read_mat()`, which relies on `SciPy`.
#' This approach may be fasterthan the default approach using `R.matlab::readMat()`, especially for large `.mat` files.
#' To enable this functionality, ensure Python is properly configured with the required dependencies.
#' You can initialize the Python environment and install necessary packages using `ifcb_py_install()`.
#'
#' If `use_python = FALSE` or if `SciPy` is not available, the function falls back to using `R.matlab::readMat()`.
#'
#' @export
#' @seealso \code{\link{ifcb_extract_pngs}} \code{\link{ifcb_extract_classified_images}} \url{https://github.com/hsosik/ifcb-analysis}
#' @references Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
#' @examples
#' \dontrun{
#' ifcb_extract_annotated_images(
#'   manual_folder = "path/to/manual_folder",
#'   class2use_file = "path/to/class2use_file.mat",
#'   roi_folders = "path/to/roi_folder",
#'   out_folder = "path/to/out_folder",
#'   skip_class = 1
#' )
#' }
ifcb_extract_annotated_images <- function(manual_folder, class2use_file, roi_folders, out_folder,
                                          skip_class = NA, verbose = TRUE, manual_recursive = FALSE,
                                          roi_recursive = TRUE, overwrite = FALSE, use_python = FALSE,
                                          roi_folder = deprecated()) {

  # Warn the user if roi_folder is used
  if (lifecycle::is_present(roi_folder)) {
    # Signal the deprecation to the user
    lifecycle::deprecate_warn("0.4.3",
                              "iRfcb::ifcb_extract_annotated_images(roi_folder = )",
                              "iRfcb::ifcb_extract_annotated_images(roi_folders = )",
                              "ifcb_extract_annotated_images now handles multiple input roi folders")

    roi_folders <- roi_folder
  }

  # Get the list of classified files
  manualfiles <- list.files(manual_folder, pattern = "mat$", full.names = TRUE, recursive = manual_recursive)

  if (length(manualfiles) == 0) {
    stop("No manual files found in the specified directory.")
  }

  # Get the class names from the specified file
  class2use <- ifcb_get_mat_variable(class2use_file)

  # Process each manual file
  for (manual_file in manualfiles) {

    if (file.size(manual_file) == 0) {
      warning(paste("Empty .mat file:", manual_file, "Skipping."))
      next
    }

    sample <- basename(tools::file_path_sans_ext(manual_file))

    if (use_python && scipy_available()) {
      manual.mat <- ifcb_read_mat(manual_file)
    } else {
      # Read the contents of the MAT file
      manual.mat <- read_mat(manual_file)
    }

    # Get the list of ROI files matching the sample from multiple folders
    roifiles <- unlist(lapply(roi_folders, function(folder) {
      list.files(folder, pattern = ".roi$", full.names = TRUE, recursive = roi_recursive)
    }))

    roifilename <- roifiles[grepl(sample, roifiles)]

    if (length(roifilename) == 0) {
      warning(paste("ROI file for sample", sample, "not found. Skipping this sample."))
      next
    }

    # Extract the taxa list from the manual.mat data
    taxa.list <- as.data.frame(manual.mat$classlist)
    names(taxa.list) <- unlist(manual.mat$list_titles)

    # Create a lookup table from class2use
    lookup_table <- data.frame(
      manual = seq_along(class2use),
      name = class2use
    )

    # Convert skip_class names to manual IDs if they are character strings
    if (is.character(skip_class)) {
      filtered_skip_class <- lookup_table %>% filter(name %in% skip_class)
      if (nrow(filtered_skip_class) == 0) {
        stop("None of the class names provided in skip_class were found in class2use.")
      }
      skip_class <- filtered_skip_class %>% pull(manual)
    }

    # Remove the skip class and NA values from the taxa list
    taxa.list <- taxa.list[!taxa.list$manual %in% skip_class & !is.na(taxa.list$manual), ]

    # Replace the numbers in taxa.list$manual with the corresponding names
    taxa.list <- merge(taxa.list, lookup_table, by = "manual", all.x = TRUE)
    taxa.list$class <- ifelse(is.na(taxa.list$name), as.character(taxa.list$manual), taxa.list$name)
    taxa.list$name <- NULL

    # Get the unique classes
    unique_classes <- unique(taxa.list$class)

    # Process each unique class
    for (class_name in unique_classes) {
      taxa.list_ix <- taxa.list[taxa.list$class == class_name, ]

      # Generate taxaname for each ROI number
      taxaname_list <- paste(class_name, sprintf("%03d", taxa.list_ix$manual), sep = "_")

      # Extract PNGs for each ROI number with corresponding taxaname
      ifcb_extract_pngs(roifilename,
                        out_folder = out_folder,
                        ROInumbers = taxa.list_ix$`roi number`,
                        taxaname = paste(unique(taxa.list_ix$class), sprintf("%03d", unique(taxa.list_ix$manual)), sep = "_"),
                        verbose = verbose,
                        overwrite = overwrite
                        )
    }
  }
}
