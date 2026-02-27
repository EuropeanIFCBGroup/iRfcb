utils::globalVariables("class_id")
#' Create Manual Classification MAT Files from PNG Subfolders
#'
#' This function creates manual classification `.mat` files compatible with the
#' code in the `ifcb-analysis` MATLAB repository (Sosik and Olson 2007) by
#' mapping ROIs to class IDs based on user-provided PNG images (organized into
#' subfolders named after classes) and a `class2use` MAT file.
#'
#' @param png_folder Directory containing PNG images organized into
#'   subfolders named after classes. Each PNG file represents a single ROI
#'   extracted from an IFCB sample and must follow the standard IFCB naming
#'   convention (for example, `"D20220712T210855_IFCB134_00042.png"`), which
#'   is used to map the image to the corresponding ROI index in the ADC file.
#' @param adc_folder Directory containing ADC files for the samples.
#' @param class2use_file Path to a `class2use` MAT file. This file should
#'   contain the vector of classes used for matching PNG annotations to class IDs.
#' @param output_folder Directory where the resulting MAT files will be written.
#'   If the folder does not exist, it will be created automatically.
#' @param sample_names Optional character vector of IFCB sample names
#'   (e.g., `"D20220712T210855_IFCB134"`). If `NULL` (default), all samples
#'   detected from the PNG filenames in `png_folder` will be processed.
#'   Each sample must have a corresponding ADC file in `adc_folder`.
#' @param unclassified_id An integer specifying the class ID to use for unclassified
#'   regions of interest (ROIs) when creating new manual `.mat` files. Default is `1`.
#' @param remove_trailing_numbers Logical. If TRUE (default), trailing numeric
#'   suffixes are removed from PNG subfolder names before matching them to
#'   entries in `class2use` (for example, `"Skeletonema_036"` becomes
#'   `"Skeletonema"`). This is useful when class folders include numeric
#'   identifiers that are not part of the class names in `class2use`.
#' @param do_compression A logical value indicating whether to compress the `.mat` file. Default is TRUE.
#'
#' @details
#' Python must be installed to use this function. The required python packages can be installed in a virtual environment using `ifcb_py_install()`.
#'
#' Each sample should have ADC files in `adc_folder` and corresponding PNG images
#' stored in subfolders under `png_folder`, where each subfolder is named after
#' a class (e.g., `Skeletonema`, `Dinophysis_acuminata`, `unclassified`). The function
#' automatically maps PNG filenames to ROI indices, assigns class IDs based on
#' `class2use`, and writes the resulting MAT file in `output_folder`.
#'
#' - The function reads all PNG images in subfolders of `png_folder`, extracts
#'   class names from folder names, and converts PNG filenames to ROI indices
#'   using `ifcb_convert_filenames()`.
#' - Class IDs are assigned using `match()` against `class2use`. If any
#'   classes cannot be matched, a warning lists the unmatched classes and
#'   shows the `ifcb_get_mat_variable()` command to inspect available classes.
#' - The function writes one MAT file per sample using
#'   `ifcb_create_manual_file()`.
#'
#' @seealso \code{\link{ifcb_py_install}} \code{\link{ifcb_create_class2use}} \url{https://github.com/hsosik/ifcb-analysis}
#' @references Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
#'
#' @examples
#' \dontrun{
#' # Example: Annotate a single IFCB sample
#' sample_names <- "D20220712T210855_IFCB134"
#' png_folder <- "data/annotated_png_images/"
#' adc_folder <- "data/raw"
#' class2use_file <- "data/manual/class2use.mat"
#' output_folder <- "data/manual/"
#'
#' # Create manual MAT file for this sample
#' ifcb_annotate_samples(
#'   png_folder = png_folder,
#'   adc_folder = adc_folder,
#'   class2use_file = class2use_file,
#'   output_folder = output_folder,
#'   sample_names = sample_names
#' )
#' }
#'
#' @return Invisibly returns `TRUE` on successful completion.
#' @export
ifcb_annotate_samples <- function(png_folder,
                                  adc_folder,
                                  class2use_file,
                                  output_folder,
                                  sample_names = NULL,
                                  unclassified_id = 1,
                                  remove_trailing_numbers = TRUE,
                                  do_compression = TRUE) {

  # Initialize python check
  check_python_and_module()

  # Input checks
  if (!dir.exists(png_folder)) {
    stop("PNG directory does not exist: ", png_folder)
  }

  if (!dir.exists(adc_folder)) {
    stop("ADC directory does not exist: ", adc_folder)
  }

  if (!file.exists(class2use_file)) {
    stop("class2use file does not exist: ", class2use_file)
  }

  if (!dir.exists(output_folder)) {
    dir.create(output_folder, recursive = TRUE)
  }

  # List files
  png_images <- list.files(
    png_folder,
    pattern = "\\.png$",
    recursive = TRUE,
    full.names = TRUE
  )

  if (length(png_images) == 0) {
    stop("No PNG images found in: ", png_folder)
  }

  adc_files <- list.files(
    adc_folder,
    pattern = "\\.adc$",
    recursive = TRUE,
    full.names = TRUE
  )

  if (length(adc_files) == 0) {
    stop("No ADC files found in: ", adc_folder)
  }

  # Build annotation table
  annotation <- tibble(
    class = basename(dirname(png_images)),
    ifcb_convert_filenames(basename(png_images))
  )

  if (remove_trailing_numbers) {
    annotation$class <- truncate_folder_name(annotation$class)
  }

  if (is.null(sample_names)) {
    sample_names <- unique(annotation$sample)
  }

  # Read class2use
  class2use <- ifcb_get_mat_variable(
    mat_file = class2use_file,
  )

  unique_classes <- unique(annotation$class)

  classes <- tibble(
    class = unique_classes,
    class_id = match(unique_classes, class2use, nomatch = NA)
  )

  na_classes <- classes$class[is.na(classes$class_id)]

  if (length(na_classes) > 0) {
    warning(
      sprintf(
        paste(
          "Some classes could not be matched to class_id values.",
          "Unmatched classes: %s",
          "Inspect available classes with: ifcb_get_mat_variable('%s')",
          sep = "\n"
        ),
        paste(na_classes, collapse = ", "),
        class2use_file
      )
    )
  }

  # Process samples
  for (smp in sample_names) {

    adc_file <- adc_files[grepl(smp, adc_files)]

    if (length(adc_file) == 0) {
      stop("No ADC file found for sample: ", smp)
    }

    if (length(adc_file) > 1) {
      warning(
        "Multiple ADC files found for sample: ", smp,
        ". Using the first match: ", basename(adc_file[1])
      )
      adc_file <- adc_file[1]
    }

    adc_data <- read_adc_columns(adc_file)

    # Identify trigger without an image from ROIwidth and ROIheight
    roi_cols <- adc_get_roi_columns(adc_data)
    empty_triggers <- which(roi_cols$x == 0 & roi_cols$y == 0)

    annotation_sample <- annotation %>%
      dplyr::filter(sample == smp)

    if (nrow(annotation_sample) == 0) {
      warning("No PNG annotations found for sample: ", smp)
    }

    classlist <- tibble(
      roi = as.integer(rownames(adc_data))
    ) %>%
      dplyr::left_join(annotation_sample, by = "roi") %>%
      dplyr::left_join(classes, by = "class") %>%
      dplyr::mutate(
        class_id = dplyr::coalesce(class_id, unclassified_id)
      )

    # Set empty triggers to NaN
    classlist$class_id[empty_triggers] <- NaN

    output_file <- file.path(output_folder, paste0(smp, ".mat"))

    ifcb_create_manual_file(
      roi_length = nrow(adc_data),
      class2use = class2use,
      output_file = output_file,
      classlist = classlist$class_id,
      do_compression = do_compression
    )
  }

  invisible(TRUE)
}
