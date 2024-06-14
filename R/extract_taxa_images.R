#' Extract Taxa Images from Classified Sample
#'
#' This function reads a classified sample file, extracts specified taxa images from the corresponding ROI files,
#' and saves each image in a specified directory.
#'
#' @param sample A character string specifying the sample name.
#' @param classifier A character string specifying the classifier name.
#' @param ifcb_path A character string specifying the base path to the IFCB data.
#' @param taxa A character string specifying the taxa to extract. Default is "All".
#' @param ifcb_unit A character string specifying the IFCB unit. Default is "IFCB134".
#' @param version A character string specifying the version of the classified data. Default is "v1".
#' @return No return value, called for side effects. Extracts and saves taxa images to a directory.
#' @examples
#' \dontrun{
#' # Extract taxa images from classified sample
#' classifier <- "Baltic"
#' sample <- "D20230311T092911"
#' extract_taxa_images(sample, classifier, "path/to/ifcb_data")
#' }
#' @import tidyverse
#' @import here
#' @import R.matlab
#' @export
extract_taxa_images <- function(sample,
                                classifier,
                                ifcb_path,
                                taxa = "All",
                                ifcb_unit = "IFCB134",
                                version = "v1") {
  # Define year
  year <- substr(sample, start = 2, stop = 5)

  # Define paths
  classifieddir <- file.path(ifcb_path, "classified", classifier, year)
  datadir <- file.path(ifcb_path, "data", year)
  outdir <- file.path(ifcb_path, "classified_images", classifier)

  # Store classified sample filename
  classifiedfilename <- paste0(sample, "_", ifcb_unit, "_class_", version, ".mat")

  # Read classified file
  classified.mat <- readMat(file.path(classifieddir, classifiedfilename))

  # Store roi filename
  roifilename <- paste0(substr(sample, 1, 9), "/", sample, "_", ifcb_unit, ".roi")

  # Extract taxa list
  taxa.list <- as.data.frame(do.call(rbind, do.call(rbind, classified.mat$TBclass)), classified.mat$roinum) %>%
    rownames_to_column("ROI")

  if (taxa != "All") {
    taxa.list <- taxa.list %>%
      filter(V1 == taxa)
  }

  # Loop for each taxa
  if (nrow(taxa.list) > 0) {
    for (i in seq_along(unique(taxa.list$V1))) {
      tryCatch({
        taxa.list.ix <- taxa.list %>%
          filter(V1 == unique(taxa.list$V1)[[i]])

        extract_taxa_images_from_ROI(
          file.path(datadir, roifilename),
          outdir,
          unique(taxa.list.ix$V1),
          as.numeric(taxa.list.ix$ROI)
        )
      }, error = function(e) {
        cat("Error occurred:", conditionMessage(e), "\n")
        Sys.sleep(10) # Pause for 10 seconds
      })
    }
  }
}
