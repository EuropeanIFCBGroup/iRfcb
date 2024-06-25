[![R-CMD-check](https://github.com/anderstorstensson/iRfcb/actions/workflows/r-cmd-check.yml/badge.svg?event=push)](https://github.com/anderstorstensson/iRfcb/actions/workflows/r-cmd-check.yml)

# iRfcb

The `iRfcb` R package provides tools for working with Imaging FlowCytobot (IFCB) data, including quality control, particle size distribution analysis, and handling of annotated image data. This package facilitates the processing, analysis, and preparation of IFCB data for publication. The primary goal is to streamline the workflow for researchers working with IFCB data.

## Installation

You can install the package from GitHub using the `devtools` package:
```r
devtools::install_github("anderstorstensson/iRfcb")
```

## Getting Started

Load the `iRfcb` library:
```r
# install.packages("devtools")
library(iRfcb)
```

## Download Sample Data

Download the sample data to get started:
```r
ifcb_download_test_data("data")
```

## Run QC/QA Checks

Before running quality checks, ensure the necessary Python environment is set up:
```r
ifcb_py_install(envname = ".virtualenvs/iRfcb")
```

### Run Particle Size Distribution QC

Run the particle size distribution quality control checks with the following parameters:
```r
psd <- ifcb_psd("data/features/2023",
                "data/data/2023",
                beads = 10 ** 12,
                bubbles = 150,
                incomplete = c(1500, 3),
                missing_cells = 0.7,
                biomass = 1000,
                bloom = 5,
                humidity = 70)

print(psd$fits)
print(psd$flags)
```

### Check if IFCB is Near Land

To determine if the Imaging FlowCytobot (IFCB) is near land (in harbor):
```r
gps_data <- ifcb_read_hdr_data("data/data/", gps_only = TRUE)

gps_data$near_land <- ifcb_is_near_land(as.numeric(gps_data$gpsLatitude), as.numeric(gps_data$gpsLongitude))

print(gps_data)
```

## Annotated Files

### Count and Summarize Annotated Image Data

#### PNG Directory

Summarize the annotated image data at the sample and class levels:
```r
png_per_sample <- ifcb_summarize_png_data(png_folder = "data/png",
                                          hdr_folder = "data/data",
                                          sum_level = "sample")

png_per_class <- ifcb_summarize_png_data(png_folder = "data/png",
                                         sum_level = "class")

print(png_per_sample)
print(png_per_class)
```

#### MATLAB Files

Count the annotations in the MATLAB files:
```r
mat_count <- ifcb_count_mat_annotations(manual_folder = "data/manual",
                                        class2use_file = "data/config/class2use.mat",
                                        skip_class = "unclassified")

print(mat_count)
```

### Run Image Gallery

To visually inspect and correct annotations, run the image gallery:
```r
ifcb_run_image_gallery()
```

### Correct .mat Files After Checking Images in the App

After reviewing images in the gallery, correct the .mat files:
```r
ifcb_correct_annotation(manual_folder = "data/manual",
                        out_folder = "data/manual",
                        correction_file = "data/Alexandrium_pseudogonyaulax_selected_images.txt",
                        correct_classid = 1) # Change to unclassified
```

### Replace Specific Class Annotations

Replace all instances of a specific class with "unclassified":
```r
# Get class2use
class_name <- ifcb_get_mat_names("data/config/class2use.mat")
class2use <- ifcb_get_mat_variable("data/config/class2use.mat",
                                   variable_name = class_name)

# Find the class id of Alexandrium_pseudogonyaulax
ap_id <- which(grepl("Alexandrium_pseudogonyaulax", class2use))

# Move all Alexandrium_pseudogonyaulax images to unclassified
ifcb_replace_mat_values(manual_folder = "data/manual",
                        out_folder = "data/manual",
                        target_id = ap_id,
                        new_id = 1)
```

### Extract Annotated Images

Extract annotated images, skipping the "unclassified" category:
```r
ifcb_extract_annotated_images(manual_folder = "data/manual",
                              class2use_file = "data/config/class2use.mat",
                              roi_folder = "data/data",
                              out_folder = "data/extracted_images",
                              skip_class = 1) # Skip unclassified
```

### Verify Correction

Verify that the corrections have been applied:
```r
png_per_class <- ifcb_summarize_png_data(png_folder = "data/extracted_images",
                                         sum_level = "class")

print(png_per_class)
```

## Prepare Zip-Packages for Publication

### PNG Directory

Prepare the PNG directory for publication:
```r
ifcb_zip_pngs(png_folder = "data/extracted_images",
              zip_filename = "zip/smhi_ifcb_skagerrak_kattegat_annotated_images_corrected.zip",
              readme_file = system.file("exdata/README-template.md", package = "iRfcb"),
              email_address = "tutorial@test.com",
              version = "1.1")
```

### MATLAB Directory

Prepare the MATLAB directory for publication:
```r
ifcb_zip_matlab(
  manual_folder = "data/manual",
  features_folder = "data/features",
  class2use_file = "data/config/class2use.mat",
  zip_filename = "zip/smhi_ifcb_skagerrak_kattegat_matlab_files_corrected.zip",
  data_folder = "data/data",
  readme_file = system.file("exdata/README-template.md", package = "iRfcb"),
  matlab_readme_file = system.file("exdata/MATLAB-template.md", package = "iRfcb"),
  email_address = "tutorial@test.com",
  version = "1.1"
)
```

### Create MANIFEST.txt

Create a manifest file for the zip packages:
```r
ifcb_create_manifest("zip/")
```

## MISC

### Extract .png from a Sample

Extract all images from a sample:
```r
ifcb_extract_pngs("data/data/2023/D20230314/D20230314T001205_IFCB134.roi")
```

Extract specific ROIs:
```r
ifcb_extract_pngs("data/data/2023/D20230314/D20230314T003836_IFCB134.roi",
                  ROInumbers = c(2, 5))
```

### Extract Timestamps from Filenames

Extract timestamps from filenames:
```
filenames <- c("D20230314T001205_IFCB134", "D20230615T123045_IFCB135")
timestamps <- ifcb_convert_filenames(filenames)
print(timestamps)
```

With ROI numbers:
```
filenames <- c("D20230314T001205_IFCB134_0023.png", "D20230615T123045_IFCB135")
timestamps <- ifcb_convert_filenames(filenames)
print(timestamps)
```

### Get Volume Analyzed in ml

Get the volume analyzed from a header file:
```
hdr_file <- "data/data/2023/D20230314/D20230314T001205_IFCB134.hdr"

volume_analyzed <- ifcb_volume_analyzed(hdr_file)
print(volume_analyzed)
```

### Get Runtime

Get the runtime from a header file:
```r
run_time <- ifcb_get_runtime(hdr_file)
print(run_time)
```

## Working with Classified Results from MATLAB

### Extract Classified Results from a Sample

Extract classified results from a sample:
```r
ifcb_extract_classified_images(sample = "D20230311T092911_IFCB135",
                               classified_folder = "path/to/classified_folder",
                               roi_folder = "path/to/roi_folder",
                               out_folder = "path/to/outputdir",
                               taxa = "All", # or specify a particular taxa
                               threshold = "opt") # or specify another threshold
```

### Read a Summary File

Read a summary file:
```r
summary_data <- ifcb_read_summary("path/to/summary_file.mat",
                                  biovolume = TRUE,
                                  threshold = "opt")
```

This concludes the tutorial for the `iRfcb` package. For more detailed information, refer to the package documentation. Happy analyzing!

## Repository

For more details and the latest updates, visit the [GitHub repository](https://github.com/anderstorstensson/iRfcb).

## License

This package is licensed under the MIT License.
