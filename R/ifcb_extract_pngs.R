#' Extract Images from IFCB ROI File
#'
#' This function reads an IFCB (.roi) file and its corresponding .adc file, extracts regions of interest (ROIs),
#' and saves each ROI as a PNG image in a specified directory. Optionally, you can specify ROI numbers
#' to extract, useful for specific ROIs from manual or automatic classification results.
#'
#' @param roi_file A character string specifying the path to the .roi file.
#' @param out_folder A character string specifying the directory where the PNG images will be saved. Defaults to the directory of the ROI file.
#' @param ROInumbers An optional numeric vector specifying the ROI numbers to extract. If NULL, all ROIs with valid dimensions are extracted.
#' @param taxaname An optional character string specifying the taxa name for organizing images into subdirectories. Defaults to NULL.
#' @param gamma A numeric value for gamma correction applied to the image. Default is 1 (no correction). Values <1 increase contrast in dark regions, while values >1 decrease contrast.
#' @param verbose A logical value indicating whether to print progress messages. Default is TRUE.
#' @param overwrite A logical value indicating whether to overwrite existing PNG files. Default is FALSE.
#'
#' @return This function is called for its side effects: it writes PNG images to a directory.
#'
#' @examples
#' \dontrun{
#' # Convert ROI file to PNG images
#' ifcb_extract_pngs("path/to/your_roi_file.roi")
#'
#' # Extract specific ROI numbers from ROI file
#' ifcb_extract_pngs("path/to/your_roi_file.roi", "output_directory", ROInumbers = c(1, 2, 3))
#' }
#' @export
#' @seealso \code{\link{ifcb_extract_classified_images}} for extracting ROIs from automatic classification.
#' @seealso \code{\link{ifcb_extract_annotated_images}} for extracting ROIs from manual annotation.
ifcb_extract_pngs <- function(roi_file, out_folder = dirname(roi_file), ROInumbers = NULL, taxaname = NULL, gamma = 1, verbose = TRUE, overwrite = FALSE) {
  # Create output directory if needed
  if (!is.null(taxaname)) {
    outpath <- file.path(out_folder, taxaname)
  } else {
    outpath <- file.path(out_folder, tools::file_path_sans_ext(basename(roi_file)))
  }
  dir.create(outpath, showWarnings = FALSE, recursive = TRUE)

  # Get ADC data for start byte and length of each ROI
  adcfile <- sub("\\.roi$", ".adc", roi_file)
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
    fid <- file(roi_file, "rb")
  }, error = function(e) {
    cat("An error occurred:", conditionMessage(e), "\n")
    NULL
  })

  # Loop over ROIs and save PNG images
  if (verbose) cat(paste("Writing", length(x[x > 0]), "ROIs from", basename(roi_file), "to", outpath), "\n")
  for (count in seq_along(ROInumbers)) {
    if (x[count] > 0) {
      num <- ROInumbers[count]
      pngname <- paste0(tools::file_path_sans_ext(basename(roi_file)), "_", sprintf("%05d", num), ".png")
      pngfile <- file.path(outpath, pngname)

      if (!file.exists(pngfile) || overwrite) {
        seek(fid, startbyte[count])
        img_data <- readBin(fid, raw(), n = x[count] * y[count])  # Read img pixels as raw
        img_matrix <- matrix(as.integer(img_data), ncol = x[count], byrow = TRUE)  # Reshape to original x-y array

        tryCatch({
          # Normalize pixel values to [0,1] using min-max scaling
          img_matrix <- (img_matrix - min(img_matrix)) / (max(img_matrix) - min(img_matrix))

          # Apply gamma correction only if gamma != 1
          if (gamma != 1) {
            img_matrix <- img_matrix^gamma
          }

          # Save using png::writePNG
          png::writePNG(img_matrix, pngfile)
        }, error = function(e) {
          cat("An error occurred:", conditionMessage(e), "\n")
        })
      } else {
        if (verbose) cat("PNG file already exists:", pngfile, "\n")
      }
    }
  }

  # Close the roi file
  close(fid)
}
