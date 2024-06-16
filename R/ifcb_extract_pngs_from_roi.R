#' Extract Images from ROI File
#'
#' This function reads a .roi file and its corresponding .adc file, extracts specified regions of interest (ROIs),
#' and saves each ROI as a PNG image in a specified directory. Optionally, you can specify a taxa name and ROI numbers.
#'
#' @param roifile A character string specifying the path to the .roi file.
#' @param outdir A character string specifying the directory where the PNG images will be saved. Defaults to the directory of the ROI file.
#' @param taxaname An optional character string specifying the taxa name for the subdirectory where images will be saved. Defaults to NULL.
#' @param ROInumbers An optional numeric vector specifying the ROI numbers to extract. If NULL, all ROIs with valid dimensions are extracted.
#' @return No return value, called for side effects. Writes PNG images to a directory.
#' @examples
#' \dontrun{
#' # Convert ROI file to PNG images
#' ifcb_extract_pngs_from_roi("your_roi_file.roi")
#'
#' # Extract taxa images from ROI file
#' ifcb_extract_pngs_from_roi("your_roi_file.roi", "output_directory", "taxa_name")
#' }
#' @importFrom imager as.cimg save.image
#' @export
ifcb_extract_pngs_from_roi <- function(roifile, outdir = dirname(roifile), taxaname = NULL, ROInumbers = NULL) {
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

  # Function to convert binary to 0-255
  convert_to_0_255 <- function(binary_value) {
    decimal_value <- as.integer(paste0("0x", binary_value))
    rescaled_value <- as.integer((decimal_value / 255) * 255)
    return(rescaled_value)
  }

  # Loop over classes and save PNG images to subdirs
  cat(paste("Writing", length(ROInumbers), "ROIs from sample", basename(roifile), "to", outpath), "\n")
  for (count in seq_along(ROInumbers)) {
    if (x[count] > 0) {
      num <- ROInumbers[count]
      pngname <- paste0(tools::file_path_sans_ext(basename(roifile)), "_", sprintf("%05d", num), ".png")
      pngfile <- file.path(outpath, pngname)

      if (!file.exists(pngfile)) {
        seek(fid, startbyte[count])
        img_data <- readBin(fid, raw(), n = x[count] * y[count])  # Read img pixels as raw
        img_matrix <- matrix(unlist(img_data), ncol = x[count], byrow = TRUE)  # Reshape to original x-y array
        img_matrix <- apply(img_matrix, 2, convert_to_0_255)  # Convert to 0-255 range

        tryCatch({
          # Convert the integers to the appropriate data type for PNG
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
