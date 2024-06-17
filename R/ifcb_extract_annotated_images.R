#' Extract Annotated Images from IFCB Data
#'
#' This function extracts labelled images from IFCB (Imaging FlowCytobot) data,
#' annotated using the MATLAB code from the ifcb-analysis repository.
#' It reads manually classified data, maps class indices to class names, and extracts
#' the corresponding Region of Interest (ROI) images, saving them to the specified directory.
#'
#' @param manualdir A character string specifying the path to the directory containing the manually classified .mat files.
#' @param class2use_file A character string specifying the path to the file containing class names.
#' @param roidir A character string specifying the path to the directory containing the ROI files.
#' @param outdir A character string specifying the output directory where the extracted images will be saved.
#' @param skip_class A numeric value or vector specifying the class(es) to be skipped during the extraction process, e.g. unclassified. Default is NA.
#'
#' @importFrom R.matlab readMat
#' @importFrom tools file_path_sans_ext
#'
#' @return None. The function saves the extracted PNG images to the specified output directory.
#'
#' @export
#' @seealso \code{\link{ifcb_extract_pngs}} \code{\link{ifcb_extract_classified_images}} \url{https://github.com/hsosik/ifcb-analysis}
#'
#' @examples
#' \dontrun{
#' ifcb_extract_annotated_images(
#'   manualdir = "path/to/manualdir",
#'   class2use_file = "path/to/class2use_file.mat",
#'   roidir = "path/to/roidir",
#'   outdir = "path/to/outdir",
#'   skip_class = 1
#' )
#' }
ifcb_extract_annotated_images <- function(manualdir, class2use_file, roidir, outdir, skip_class = NA) {

  # Get the list of classified files
  manualfiles <- list.files(manualdir, pattern = "mat$", full.names = TRUE, recursive = FALSE)

  if (length(manualfiles) == 0) {
    stop("No manual files found in the specified directory.")
  }

  # Get the class names from the specified file
  class2use <- ifcb_get_mat_classes(class2use_file)

  # Process each manual file
  for (file in manualfiles) {
    sample <- basename(tools::file_path_sans_ext(file))

    manual.mat <- readMat(file)

    # Get the list of ROI files matching the sample
    roifiles <- list.files(roidir, pattern = ".roi$", full.names = TRUE, recursive = TRUE)
    roifilename <- roifiles[grepl(sample, roifiles)]

    if (length(roifilename) == 0) {
      warning(paste("ROI file for sample", sample, "not found. Skipping this sample."))
      next
    }

    # Extract the taxa list from the manual.mat data
    taxa.list <- as.data.frame(manual.mat$classlist)
    names(taxa.list) <- unlist(manual.mat$list.titles)

    # Remove the skip class and NA values from the taxa list
    taxa.list <- taxa.list[!taxa.list$manual %in% skip_class & !is.na(taxa.list$manual), ]

    # Create a lookup table from class2use
    lookup_table <- data.frame(
      manual = seq_along(class2use),
      name = class2use
    )

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
                        outdir = outdir,
                        taxaname = paste(unique(taxa.list_ix$class), sprintf("%03d", unique(taxa.list_ix$manual)), sep = "_"),
                        ROInumbers = taxa.list_ix$`roi number`)
    }
  }
}
