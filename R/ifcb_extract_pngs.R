#' Extract Images from IFCB ROI File
#'
#' This function reads an IFCB (.roi) file and its corresponding .adc file, extracts regions of interest (ROIs),
#' and saves each ROI as a PNG image in a specified directory. Optionally, you can specify ROI numbers
#' to extract, useful for specific ROIs from manual or automatic classification results.
#'
#' @param roifile A character string specifying the path to the .roi file.
#' @param outdir A character string specifying the directory where the PNG images will be saved. Defaults to the directory of the ROI file.
#' @param ROInumbers An optional numeric vector specifying the ROI numbers to extract. If NULL, all ROIs with valid dimensions are extracted.
#' @param taxaname An optional character string specifying the taxa name for organizing images into subdirectories. Defaults to NULL.
#' @return This function is called for its side effects: it writes PNG images to a directory.
#' @examples
#' \dontrun{
#' # Convert ROI file to PNG images
#' ifcb_extract_pngs("path/to/your_roi_file.roi")
#'
#' # Extract specific ROI numbers from ROI file
#' ifcb_extract_pngs("path/to/your_roi_file.roi", "output_directory", ROInumbers = c(1, 2, 3))
#' }
#' @importFrom imager as.cimg save.image
#' @export
#' @seealso \code{\link{ifcb_extract_classified_images}} for extracting ROIs from automatic classification.
#' @seealso \code{\link{ifcb_extract_annotated_images}} for extracting ROIs from manual annotation.
ifcb_extract_pngs <- function(roifile, outdir = dirname(roifile), ROInumbers = NULL, taxaname = NULL) {
  # Create output directory if needed
  if (!is.null(taxaname)) {
    outpath <- file.path(outdir, taxaname)
  } else {
    outpath <- file.path(outdir, tools::file_path_sans_ext(basename(roifile)))
  }
  dir.create(outpath, showWarnings = FALSE, recursive = TRUE)

  # Get ADC data for start byte and length of each ROI
  adcfile <- sub("\\.roi$", ".adc", roifile)
  adcdata <- read.csv(adcfile, header = FALSE, sep = ",")
  x <- as.numeric(adcdata$V16)
  y <- as.numeric(adcdata$V17)
  startbyte <- as.numeric(adcdata$V18)

  if (!is.null(ROInumbers)) {
    adcdata <- adcdata[ROInumbers,]
    x <- as.numeric(adcdata$V16)
    y <- as.numeric(adcdata$V17)
    startbyte <- as.numeric(adcdata$V18)
  } else {
    ROInumbers <- seq_along(startbyte)
  }

  # Open roi file
  tryCatch({
    fid <- file(roifile, "rb")
  }, error = function(e) {
    # Handle the error
    cat("An error occurred:", conditionMessage(e), "\n")
    return(NULL)
  })

  # Loop over ROIs and save PNG images
  cat(paste("Writing", length(ROInumbers), "ROIs from", basename(roifile), "to", outpath), "\n")
  for (count in seq_along(ROInumbers)) {
    if (x[count] > 0) {
      num <- ROInumbers[count]
      pngname <- paste0(tools::file_path_sans_ext(basename(roifile)), "_", sprintf("%05d", num), ".png")
      pngfile <- file.path(outpath, pngname)

      if (!file.exists(pngfile)) {
        seek(fid, startbyte[count])
        img_data <- readBin(fid, raw(), n = x[count] * y[count])  # Read img pixels as raw
        img_matrix <- matrix(as.integer(img_data), ncol = x[count], byrow = TRUE)  # Reshape to original x-y array

        # Correct orientation: Rotate 90 degrees counterclockwise
        img_matrix <- t(img_matrix)  # Rotate 90 degrees counterclockwise

        tryCatch({
          # Convert matrix to image object
          img_matrix <- imager::as.cimg(img_matrix)

          # Write ROI in PNG format
          imager::save.image(img_matrix, pngfile)
        }, error = function(e) {
          # Handle the error
          cat("An error occurred:", conditionMessage(e), "\n")
        })
      } else {
        cat("PNG file already exists:", pngfile, "\n")
      }
    }
  }

  # Close the roi file
  close(fid)
}
