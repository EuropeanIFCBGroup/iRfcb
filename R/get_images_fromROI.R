get_images_fromROI <- function(ROIfile_withpath, ROInumbers = NULL) {
  basedir <- dirname(ROIfile_withpath)
  filename <- tools::file_path_sans_ext(basename(ROIfile_withpath))
  ROIfile <- paste0(filename, ".roi")
  
  adcfile <- paste0(filename, ".adc")
  adcdata <- read.table(file.path(basedir, adcfile), header = FALSE, sep = ",")
  x <- adcdata$V12
  y <- adcdata$V13
  startbyte <- adcdata$V14
  
  if (is.null(ROInumbers)) {
    ROInumbers <- which(x > 0)
  }
  
  fid <- file.path(basedir, ROIfile)
  con <- file(fid, "rb")
  targets <- list()
  targets$targetNumber <- ROInumbers
  targets$pid <- list()
  
  for (count in 1:length(ROInumbers)) {
    num <- ROInumbers[count]
    seek(con, where = startbyte[num] - 1)
    img <- readBin(con, what = "raw", n = x[num] * y[num], size = 1)
    targets$image[[count]] <- matrix(unlist(img), nrow = x[num], byrow = TRUE)
    targets$pid[[count]] <- paste0(filename, "_", formatC(num, width = 5, format = "f", flag = "0"))
  }
  
  close(con)
  return(targets)
}
