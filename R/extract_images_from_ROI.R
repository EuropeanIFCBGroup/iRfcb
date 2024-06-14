library(imager)

extract_images_from_ROI <- function(roifile, ROInumbers = NULL) {
  # Create output directory if needed
  roipath <- dirname(roifile)
  outpath <- file.path(roipath, tools::file_path_sans_ext(basename(roifile)))
  dir.create(outpath, showWarnings = FALSE, recursive = TRUE)
  
  # Get ADC data for start byte and length of each ROI
  adcfile <- sub("\\.roi$", ".adc", roifile)
  adcdata <- read.csv(adcfile, header = FALSE, sep = ",")
  x <- as.numeric(adcdata$V16)
  y <- as.numeric(adcdata$V17)
  startbyte <- as.numeric(adcdata$V18)
  
  if (is.null(ROInumbers)) {
    ROInumbers <- which(x > 0)
  }
  
  # Open roi file
  fid <- file(roifile, "rb")
  
  targets <- list()
  targets$targetNumber <- ROInumbers
  targets$pid <- list()
  
  # Function to convert binary to 0-255
  convert_to_0_255 <- function(binary_value) {
    decimal_value <- as.integer(paste0("0x", binary_value))
    rescaled_value <- as.integer((decimal_value / 255) * 255)
    return(rescaled_value)
  }
  
  # Loop over classes and save PNG images to subdirs
  cat(paste("Writing", length(ROInumbers), "ROIs to", outpath), "\n")
  for (count in 1:length(ROInumbers)) {
    if (x[count] > 0) {
      num <- ROInumbers[count]
      seek(fid, startbyte[num])
      img_data <- readBin(fid, raw(), n = x[num] * y[num])  # Read img pixels as raw
      img_matrix <- matrix(unlist(img_data), ncol = x[num], byrow = TRUE)  # Reshape to original x-y array
      img_matrix <- apply(img_matrix, 2, convert_to_0_255)  # Convert to 0-255 range
      
      pngname <- paste0(tools::file_path_sans_ext(basename(roifile)), "_", sprintf("%05d", num), ".png")
      pngfile <- file.path(outpath, pngname)
      
      # Convert the integers to the appropriate data type for PNG
      img_matrix <- imager::as.cimg(img_matrix)
      
      # Write ROI in PNG format
      imager::save.image(img_matrix, pngfile)
    }
  }
  
  # Close the roi file
  close(fid)
}

# Example usage:
# convert_roifile_to_pngs("your_roi_file.roi")