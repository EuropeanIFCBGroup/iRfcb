# Load libraries
library(tidyverse)
library(here)
library(R.matlab)

extract_taxa_images <- function(sample, 
                                classifier, 
                                ifcb_path, 
                                taxa = "All",
                                ifcb_unit = "IFCB134", 
                                version = "v1") {
  # Define year
  year <- substr(sample, start = 2, stop = 5)
  
  # Define paths
  classifieddir <- paste(ifcb_path, "classified", classifier, year, sep = "/")
  datadir <- paste(ifcb_path, "data", year, sep = "/")
  outdir <- paste(ifcb_path, "classified_images", classifier, sep = "/")
  
  # Store classified sample filename
  classifiedfilename <- paste0(sample, "_", ifcb_unit, "_class_", version, ".mat")
  
  # Read classified file
  classified.mat <- readMat(file.path(classifieddir, classifiedfilename))
  
  # Store roi filename
  roifilename <- paste0(substr(sample, 1, 9), "/", sample, "_", ifcb_unit, ".roi")
  
  # Extract taxa list
  taxa.list <- as.data.frame(do.call(rbind, do.call(rbind, classified.mat$TBclass)),classified.mat$roinum) %>%
    rownames_to_column("ROI") 
  
  if(!taxa == "All") {
    taxa.list <- taxa.list %>%
      filter(V1 == taxa)
  }
  
  # Loop for each taxa
  
if(nrow(taxa.list) > 0) {
  for (i in 1:length(unique(taxa.list$V1))) {
    tryCatch({
      taxa.list.ix <- taxa.list %>%
        filter(V1 == unique(taxa.list$V1)[[i]])
      
      extract_taxa_images_from_ROI(file.path(datadir, roifilename), outdir, unique(taxa.list.ix$V1), as.numeric(taxa.list.ix$ROI))
    }, error = function(e) {
      cat("Error occurred:", conditionMessage(e), "\n")
      Sys.sleep(10) # Pause for 10 seconds
    })
  }
}
  }

# Usage:
# classifier <- "Baltic"
# sample <- "D20230311T092911"
# extract_taxa_images(classifier, sample)
