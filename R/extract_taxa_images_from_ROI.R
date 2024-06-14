library(imager)

extract_taxa_images_from_ROI <- function(roifile, outdir, taxaname, ROInumbers = NULL) {
  # Create output directory if needed
  outpath <- file.path(outdir, taxaname)
  dir.create(outpath, showWarnings = FALSE, recursive = TRUE)
  
  # Get ADC data for start byte and length of each ROI
  adcfile <- sub("\\.roi$", ".adc", roifile)
  adcdata <- read.csv(adcfile, header = FALSE, sep = ",")
  adcdata <- adcdata[ROInumbers,]
  x <- as.numeric(adcdata$V16)
  y <- as.numeric(adcdata$V17)
  startbyte <- as.numeric(adcdata$V18)
  
  if (is.null(ROInumbers)) {
    ROInumbers <- which(x > 0)
  }
  
  # Open roi file
  tryCatch({
    fid <- file(roifile, "rb")
  }, error = function(e) {
    # Handle the error
    cat("An error occurred:", conditionMessage(e), "\n")
  })
  
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
  cat(paste("Writing", length(ROInumbers),"ROIs from sample", basename(roifile), "to", outpath), "\n")
  for (count in 1:length(ROInumbers)) {
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

# Example usage:
# convert_roifile_to_pngs("your_roi_file.roi")