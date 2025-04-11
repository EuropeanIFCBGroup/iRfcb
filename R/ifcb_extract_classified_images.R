#' Extract Taxa Images from MATLAB Classified Sample
#'
#' This function reads a MATLAB classified sample file (.mat) generated
#' by the `start_classify_batch_user_training` function from the `ifcb-analysis` repository (Sosik and Olson 2007),
#' extracts specified taxa images from the corresponding ROI files,
#' and saves each image in a specified directory.
#'
#' @param sample A character string specifying the sample name.
#' @param classified_folder A character string specifying the directory containing the classified files.
#' @param roi_folder A character string specifying the directory containing the ROI files.
#' @param out_folder A character string specifying the directory to save the extracted images.
#' @param taxa A character string specifying the taxa to extract. Default is "All".
#' @param threshold A character string specifying the threshold to use ("none", "opt", "adhoc"). Default is "opt".
#' @param overwrite A logical value indicating whether to overwrite existing PNG files. Default is FALSE.
#' @param scale_bar_um An optional numeric value specifying the length of the scale bar in micrometers. If NULL, no scale bar is added.
#' @param scale_micron_factor A numeric value defining the conversion factor from micrometers to pixels. Defaults to 1/3.4.
#' @param scale_bar_position A character string specifying the position of the scale bar in the image. Options are `"topright"`, `"topleft"`, `"bottomright"`, or `"bottomleft"`. Defaults to `"bottomright"`.
#' @param scale_bar_color A character string specifying the scale bar color. Options are `"black"` or `"white"`. Defaults to `"black"`.
#' @param old_adc A logical value indicating whether the `adc` file is of the old format (samples from IFCB1-6, labeled "IFCBxxx_YYYY_DDD_HHMMSS"). Default is FALSE.
#' @param gamma A numeric value for gamma correction applied to the image. Default is 1 (no correction). Values <1 increase contrast in dark regions, while values >1 decrease contrast.
#' @param use_python Logical. If `TRUE`, attempts to read the `.mat` file using a Python-based method. Default is `FALSE`.
#' @param verbose A logical value indicating whether to print progress messages. Default is TRUE.
#'
#' @return No return value, called for side effects. Extracts and saves taxa images to a directory.
#'
#' @details
#' If `use_python = TRUE`, the function tries to read the `.mat` file using `ifcb_read_mat()`, which relies on `SciPy`.
#' This approach may be faster than the default approach using `R.matlab::readMat()`, especially for large `.mat` files.
#' To enable this functionality, ensure Python is properly configured with the required dependencies.
#' You can initialize the Python environment and install necessary packages using `ifcb_py_install()`.
#'
#' If `use_python = FALSE` or if `SciPy` is not available, the function falls back to using `R.matlab::readMat()`.
#'
#' @examples
#' \dontrun{
#' # Define the parameters
#' sample <- "D20230311T092911_IFCB135"
#' classified_folder <- "path/to/classified_folder"
#' roi_folder <- "path/to/roi_folder"
#' out_folder <- "path/to/outputdir"
#' taxa <- "All"  # or specify a particular taxa
#' threshold <- "opt"  # or specify another threshold
#'
#' # Extract taxa images from the classified sample
#' ifcb_extract_classified_images(sample, classified_folder, roi_folder, out_folder, taxa, threshold)
#' }
#' @references Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
#' @seealso \code{\link{ifcb_extract_pngs}} \code{\link{ifcb_extract_annotated_images}} \url{https://github.com/hsosik/ifcb-analysis}
#' @export
ifcb_extract_classified_images <- function(sample,
                                           classified_folder,
                                           roi_folder,
                                           out_folder,
                                           taxa = "All",
                                           threshold = "opt",
                                           overwrite = FALSE,
                                           scale_bar_um = NULL,
                                           scale_micron_factor = 1/3.4,
                                           scale_bar_position = "bottomright",
                                           scale_bar_color = "black",
                                           old_adc = FALSE,
                                           gamma = 1,
                                           use_python = FALSE,
                                           verbose = TRUE) {

  # Get the list of classified files and find the one matching the sample
  classifiedfiles <- list.files(classified_folder, pattern = "mat$", full.names = TRUE, recursive = TRUE)
  classifiedfilename <- classifiedfiles[grepl(sample, classifiedfiles)]

  if (length(classifiedfilename) == 0) {
    stop("Classified file for sample not found")
  }

  if (length(classifiedfilename) > 1) {
    stop("More than one matching class file in classified folder")
  }

  # Read classified file
  if (use_python && scipy_available()) {
    classified.mat <- ifcb_read_mat(classifiedfilename)
  } else {
    # Read the contents of the MAT file
    classified.mat <- read_mat(classifiedfilename)
  }

  # Get the list of ROI files and find the one matching the sample
  roifiles <- list.files(roi_folder, pattern=".roi$", full.names = TRUE, recursive = TRUE)
  roifilename <- roifiles[grepl(sample, roifiles)]

  if (length(roifilename) == 0) {
    stop("ROI file for sample not found")
  }

  # Extract taxa list based on the specified threshold
  taxa.list <- switch(threshold,
                      "opt" = as.data.frame(classified.mat$TBclass_above_threshold),
                      "adhoc" = as.data.frame(classified.mat$TBclass_above_adhocthresh),
                      "none" = as.data.frame(classified.mat$TBclass),
                      stop("Invalid threshold specified"))

  # Rename the column
  names(taxa.list) <- "V1"

  # Add ROI column
  taxa.list$ROI <- classified.mat$roinum

  if (taxa != "All") {
    taxa.list <- taxa.list[taxa.list$V1 == taxa, ]
  }

  if (nrow(taxa.list) > 0) {
    unique_taxa <- unlist(unique(taxa.list$V1))
    for (taxon in unique_taxa) {
      tryCatch({
        taxa.list.ix <- taxa.list[taxa.list$V1 == taxon, ]

        ifcb_extract_pngs(
          roi_file = roifilename,
          out_folder = out_folder,
          ROInumbers = as.numeric(taxa.list.ix$ROI),
          taxaname = taxon,
          verbose = verbose,
          scale_bar_um =scale_bar_um,
          scale_micron_factor = scale_micron_factor,
          scale_bar_position = scale_bar_position,
          scale_bar_color = scale_bar_color,
          overwrite = overwrite,
          old_adc = old_adc,
          gamma = gamma
        )
      }, error = function(e) {
        cat("Error occurred while processing taxon", taxon, ":", conditionMessage(e), "\n")
        Sys.sleep(10) # Pause for 10 seconds
      })
    }
  } else {
    message("No taxa found to extract")
  }
}
