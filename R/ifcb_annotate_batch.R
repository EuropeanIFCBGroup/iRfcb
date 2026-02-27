#' Annotate IFCB Images with Specified Class
#'
#' This function creates or updates manual `.mat` classlist files with a user specified class in batch,
#' based on input vector of IFCB image names.
#' These `.mat` files can be used with the code in the `ifcb-analysis` repository (Sosik and Olson 2007).
#'
#' @param png_images A character vector containing the names of the PNG images to be annotated in the format DYYYYMMDDTHHMMSS_IFCBXXX_ZZZZZ.png, where XXX represent the IFCB number and ZZZZZ the roi number.
#' @param class A character string or integer specifying the class name or class2use index to annotate the images with. If a string is provided, it is matched against the available classes in `class2use_file`.
#' @param manual_folder A character string specifying the path to the folder containing the manual `.mat` classlist files.
#' @param adc_files A character string specifying the path to the folder containing the raw data, organized in subfolders by year (YYYY) and date (DYYYYMMDD), or a vector with full paths to the `.adc` files. Each ADC file is used to determine the number of regions of interest (ROIs) for each sample when creating new manual `.mat` files.
#' @param class2use_file A character string specifying the path to the `.mat` file containing class names and corresponding indices.
#' @param manual_output A character string specifying the path to the folder where updated or newly created `.mat` classlist files will be saved. If not provided, the `manual_folder` path will be used by default.
#' @param manual_recursive A logical value indicating whether to search recursively within `manual_folder` for `.mat` files. Default is `FALSE`.
#' @param unclassified_id An integer specifying the class ID to use for unclassified regions of interest (ROIs) when creating new manual `.mat` files. Default is `1`.
#' @param do_compression A logical value indicating whether to compress the .mat file. Default is TRUE.
#' @param adc_folder `r lifecycle::badge("deprecated")`
#'
#'    Use \code{adc_files} instead.
#'
#' @details
#' Python must be installed to use this function. The required python packages can be installed in a virtual environment using `ifcb_py_install()`.
#'
#' If an image belongs to a sample that already has a corresponding manual `.mat` file,
#' the function updates the class IDs for the specified regions of interest (ROIs) in that file.
#' If no manual file exists for the sample, the function creates a new one based on the sample's ADC data,
#' assigning unclassified IDs to all ROIs initially, then applying the specified class to the relevant ROIs.
#'
#' The class parameter can be provided as either a string (class name) or an integer (class index).
#' If a string is provided, the function will attempt to match it to one of the available
#' classes in `class2use_file`. If no match is found, an error is thrown.
#'
#' The function assumes that the ADC files are organized in subfolders by year (YYYY) and date (DYYYYMMDD) within `adc_files`.
#'
#' @return The function does not return a value. It creates or updates `.mat` files in the `manual_folder` to
#' reflect the specified annotations.
#'
#' @seealso \code{\link{ifcb_correct_annotation}}, \code{\link{ifcb_create_manual_file}}
#'
#' @references Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
#'
#' @examples
#' \dontrun{
#' # Initialize a python session if not already set up
#' ifcb_py_install()
#'
#' # Annotate two png images with class "Nodularia_spumigena" and update or create manual files
#' ifcb_annotate_batch(
#'   png_images = c("D20230812T162908_IFCB134_01399.png",
#'                  "D20230714T102127_IFCB134_00069.png"),
#'   class = "Nodularia_spumigena",
#'   manual_folder = "path/to/manual",
#'   adc_files = "path/to/adc",
#'   class2use_file = "path/to/class2use.mat"
#' )
#' }
#'
#' @export
ifcb_annotate_batch <- function(png_images, class, manual_folder, adc_files, class2use_file,
                                manual_output = NULL, manual_recursive = FALSE, unclassified_id = 1,
                                do_compression = TRUE, adc_folder = deprecated()) {

  # Initialize python check
  check_python_and_module()

  # Ensure that manual folder exists
  if (!dir.exists(manual_folder)) {
    dir.create(manual_folder, recursive = TRUE)
  }

  # Check if class2use_file exists
  if (!file.exists(class2use_file)) {
    stop("The specified class2use_file file does not exist")
  }

  # Warn the user if adc_folder is used
  if (lifecycle::is_present(adc_folder)) {

    # Signal the deprecation to the user
    deprecate_warn("0.5.0", "iRfcb::ifcb_annotate_batch(adc_folder = )", "iRfcb::ifcb_annotate_batch(adc_files = )")

    # Deal with the deprecated argument for compatibility
    adc_files <- adc_folder
  }

  # Write files directly to manual_folder if no other folder has been specified
  if (is.null(manual_output)) {
    manual_output <- manual_folder
  }

  # Check if hdr_files is a single folder path or a vector of file paths
  if (length(adc_files) == 1 && file.info(adc_files)$isdir) {
    adc_files <- list.files(adc_files, pattern = "\\.adc$", recursive = TRUE, full.names = TRUE)
  }

  # Get the base names of the png files
  png_name <- basename(png_images)

  # Get the list of classes
  class2use <- as.character(ifcb_get_mat_variable(class2use_file))

  # Find the correct class index based on class name (if provided as a string)
  if (is.character(class)) {
    class_match <- which(class == class2use)
    if (length(class_match) == 0) {
      stop(paste("Class", class, "not found in class2use"))
    }
    class <- class_match
  }

  # List the existing manual files and extract the sample names
  manualfiles <- list.files(manual_folder, pattern = "mat$", full.names = TRUE, recursive = manual_recursive)
  manual_sample <- gsub(".mat", "", basename(manualfiles))

  # Prepare the annotations dataframe
  annotations <- data.frame(image_filename = png_name, ifcb_convert_filenames(png_name))

  # Loop through the unique samples in the annotations
  for (sample_name in unique(annotations$sample)) {
    # Filter the annotations for the current sample
    annotations_sample <- dplyr::filter(annotations, sample == sample_name)

    # Check if this sample already has a corresponding manual file
    if (sample_name %in% manual_sample) {
      # Correct the existing manual file
      ifcb_correct_annotation(manual_folder,
                              manual_output,
                              annotations_sample$image_filename,
                              as.integer(class),
                              do_compression = do_compression)
    } else {
      # Sample doesn't have a manual file, so we create one
      sample_info <- ifcb_convert_filenames(sample_name)

      # Find the path to the ADC file
      adcfile <- adc_files[grepl(sample_name, adc_files)]

      # Check if no ADC file was found
      if (length(adcfile) == 0) {
        warning(paste("ADC file not found for sample:", sample_name))
        next
      }

      if (length(adcfile) > 1) {
        # If multiple ADC files are found, use the first one
        adcfile <- adcfile[1]

        warning("More than one .adc found for sample, will continue with: ", adcfile)
      }

      # Check if the ADC file exists
      if (!file.exists(adcfile)) {
        warning(paste("ADC file not found for sample:", sample_name))
        next
      }

      # Read the ADC data
      adcdata <- read.csv(adcfile, header = FALSE, sep = ",")
      rois <- nrow(adcdata)

      # Create an unclassifed manual file
      ifcb_create_manual_file(roi_length = as.integer(rois),
                              class2use = as.character(class2use),
                              output_file = file.path(manual_output, paste0(sample_name, ".mat")),
                              classlist = as.integer(unclassified_id),
                              do_compression = do_compression)

      # Apply corrections to the new manual file
      ifcb_correct_annotation(manual_folder,
                              manual_output,
                              annotations_sample$image_filename,
                              as.integer(class),
                              do_compression = do_compression)
    }
  }
}
