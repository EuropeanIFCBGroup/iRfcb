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
#' @return No return value, called for side effects. Extracts and saves taxa images to a directory.
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
#' @import R.matlab
#' @references Sosik, H. M. and Olson, R. J. (2007) Limnol. Oceanogr: Methods 5, 204–216.
#' @seealso \code{\link{ifcb_extract_pngs}} \code{\link{ifcb_extract_annotated_images}} \url{https://github.com/hsosik/ifcb-analysis}
#' @export
ifcb_extract_classified_images <- function(sample,
                                           classified_folder,
                                           roi_folder,
                                           out_folder,
                                           taxa = "All",
                                           threshold = "opt") {

  # Get the list of classified files and find the one matching the sample
  classifiedfiles <- list.files(classified_folder, pattern="mat$", full.names = TRUE, recursive = TRUE)
  classifiedfilename <- classifiedfiles[grepl(sample, classifiedfiles)]

  if (length(classifiedfilename) == 0) {
    stop("Classified file for sample not found")
  }

  if (length(classifiedfilename) > 1) {
    stop("More than one matching class file in classified folder")
  }

  # Read classified file
  classified.mat <- readMat(classifiedfilename)

  # Get the list of ROI files and find the one matching the sample
  roifiles <- list.files(roi_folder, pattern=".roi$", full.names = TRUE, recursive = TRUE)
  roifilename <- roifiles[grepl(sample, roifiles)]

  if (length(roifilename) == 0) {
    stop("ROI file for sample not found")
  }

  # Extract taxa list based on the specified threshold
  taxa.list <- switch(threshold,
                      "opt" = as.data.frame(do.call(rbind, classified.mat$TBclass.above.threshold), stringsAsFactors = FALSE),
                      "adhoc" = as.data.frame(do.call(rbind, classified.mat$TBclass.above.adhocthresh), stringsAsFactors = FALSE),
                      "none" = as.data.frame(do.call(rbind, classified.mat$TBclass), stringsAsFactors = FALSE),
                      stop("Invalid threshold specified"))

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
          roifilename,
          out_folder,
          as.numeric(taxa.list.ix$ROI),
          taxon
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
