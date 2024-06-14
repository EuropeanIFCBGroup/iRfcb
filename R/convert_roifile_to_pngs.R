library(imager)

convert_roifile_to_pngs <- function(roifile) {
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
  
  # Open roi file
  fid <- file(roifile, "rb")
  
  # Function to convert binary to 0-255
  convert_to_0_255 <- function(binary_value) {
    decimal_value <- as.integer(paste0("0x", binary_value))
    rescaled_value <- as.integer((decimal_value / 255) * 255)
    return(rescaled_value)
  }
  
  # Loop over classes and save PNG images to subdirs
  cat(paste("Writing", length(startbyte), "ROIs to", outpath), "\n")
  for (count in seq_along(startbyte)) {
    if (x[count] > 0) {
      seek(fid, startbyte[count])
      img_data <- readBin(fid, raw(), n = x[count] * y[count])  # Read img pixels as raw
      img_matrix <- matrix(unlist(img_data), ncol = x[count], byrow = TRUE)  # Reshape to original x-y array
      img_matrix <- apply(img_matrix, 2, convert_to_0_255)  # Convert to 0-255 range
      
      pngname <- paste0(tools::file_path_sans_ext(basename(roifile)), "_", sprintf("%05d", count), ".png")
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