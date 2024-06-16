#' Extract Taxa Images from MATLAB Classified Sample
#'
#' This function reads a MATLAB classified sample file (.mat) generated
#' by the `start_classify_batch_user_training` function from the ifcb-analysis repository,
#' extracts specified taxa images from the corresponding ROI files,
#' and saves each image in a specified directory.
#'
#' @param sample A character string specifying the sample name.
#' @param classifieddir A character string specifying the directory containing the classified files.
#' @param roidir A character string specifying the directory containing the ROI files.
#' @param outdir A character string specifying the directory to save the extracted images.
#' @param taxa A character string specifying the taxa to extract. Default is "All".
#' @param threshold A character string specifying the threshold to use ("none", "opt", "adhoc"). Default is "opt".
#' @return No return value, called for side effects. Extracts and saves taxa images to a directory.
#' @examples
#' \dontrun{
#' # Define the parameters
#' sample <- "D20230311T092911"
#' classifieddir <- "path/to/classifieddir"
#' roidir <- "path/to/roidir"
#' outdir <- "path/to/outputdir"
#' taxa <- "All"  # or specify a particular taxa
#' threshold <- "opt"  # or specify another threshold
#'
#' # Extract taxa images from the classified sample
#' ifcb_extract_classified_images(sample, classifieddir, roidir, outdir, taxa, threshold)
#' }
#' @import dplyr
#' @import tibble
#' @import R.matlab
#' @seealso \code{\link{ifcb_extract_pngs}} \url{https://github.com/hsosik/ifcb-analysis}
#' @export
ifcb_extract_classified_images <- function(sample,
                                           classifieddir,
                                           roidir,
                                           outdir,
                                           taxa = "All",
                                           threshold = "opt") {
  # Define year
  year <- substr(sample, start = 2, stop = 5)

  # Get the list of classified files and find the one matching the sample
  classifiedfiles <- list.files(classifieddir, pattern="mat$", full.names = TRUE, recursive = FALSE)
  classifiedfilename <- classifiedfiles[grepl(sample, classifiedfiles)]

  if (length(classifiedfilename) == 0) {
    stop("Classified file for sample not found")
  }

  # Read classified file
  classified.mat <- readMat(classifiedfilename)

  # Get the list of ROI files and find the one matching the sample
  roifiles <- list.files(roidir, pattern=".roi$", full.names = TRUE, recursive = TRUE)
  roifilename <- roifiles[grepl(sample, roifiles)]

  if (length(roifilename) == 0) {
    stop("ROI file for sample not found")
  }

  # Extract taxa list based on the specified threshold
  taxa.list <- switch(threshold,
                      "opt" = as.data.frame(do.call(rbind, classified.mat$TBclass.above.optthresh), stringsAsFactors = FALSE),
                      "adhoc" = as.data.frame(do.call(rbind, classified.mat$TBclass.above.adhocthresh), stringsAsFactors = FALSE),
                      "none" = as.data.frame(do.call(rbind, classified.mat$TBclass), stringsAsFactors = FALSE),
                      stop("Invalid threshold specified"))
  taxa.list <- taxa.list %>% rownames_to_column("ROI")

  if (taxa != "All") {
    taxa.list <- taxa.list %>% filter(V1 == taxa)
  }

  if (nrow(taxa.list) > 0) {
    unique_taxa <- unique(taxa.list$V1)
    for (taxon in unique_taxa) {
      tryCatch({
        taxa.list.ix <- taxa.list %>% filter(V1 == taxon)

        ifcb_extract_pngs(
          roifilename,
          outdir,
          taxon,
          as.numeric(taxa.list.ix$ROI)
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
