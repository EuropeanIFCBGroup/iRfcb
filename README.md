[![R-CMD-check](https://github.com/anderstorstensson/iRfcb/actions/workflows/r-cmd-check.yml/badge.svg?event=push)](https://github.com/anderstorstensson/iRfcb/actions/workflows/r-cmd-check.yml)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.12533225.svg)](https://doi.org/10.5281/zenodo.12533225)

# I 'R' FlowCytobot: Tools for analyzing and processing data from the Imaging FlowCytobot (IFCB) using R

The `iRfcb` R package provides tools for working with Imaging FlowCytobot (IFCB) data, including quality control, particle size distribution analysis, and handling of annotated image data. This package facilitates the processing, analysis, and preparation of IFCB images and data for publication. The primary goal is to streamline the workflow for researchers working with IFCB data, and especially useful for someone who is using, or partly using, the MATLAB [ifcb-analysis](https://github.com/hsosik/ifcb-analysis) package (Sosik and Olson 2007).

## Installation

You can install the package from GitHub using the `devtools` package:
```r
# install.packages("devtools")
devtools::install_github("EuropeanIFCBGroup/iRfcb")
```
Some functions in `iRfcb` require `Python` to be installed (see in the sections below). You can download `Python` from the official website: [python.org/downloads](https://www.python.org/downloads/).

## Getting Started

Load the `iRfcb` library:
```r
library(iRfcb)
```

## Download Sample Data

To get started, download sample data from the [SMHI IFCB Plankton image reference library](https://doi.org/10.17044/scilifelab.25883455):
```r
ifcb_download_test_data(dest_dir = "data",
                        method = "auto")
```

## Run QC/QA Checks

### Run Particle Size Distribution QC

IFCB data can be quality controlled by analyzing the particle size distribution (PSD) (Hayashi et al. in prep). `iRfcb` uses the code available at [https://github.com/kudelalab/PSD](https://github.com/kudelalab/PSD). Before running the PSD quality check, ensure the necessary Python environment is set up and activated:

```r
ifcb_py_install(envname = ".virtualenvs/iRfcb") # Or your preferred venv path

psd <- ifcb_psd(feature_folder = "data/features/2023",
                hdr_folder = "data/data/2023",
                save_data = FALSE,
                output_file = NA,
                plot_folder = NULL,
                use_marker = FALSE,
                start_fit = 10,
                r_sqr = 0.5,
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

To determine if the Imaging FlowCytobot (IFCB) is near land (i.e. in harbor), examine the position data in the .hdr files:
```r
# Read HDR data and extract GPS position (when available)
gps_data <- ifcb_read_hdr_data("data/data/",
                               gps_only = TRUE)

gps_data$near_land <- ifcb_is_near_land(as.numeric(gps_data$gpsLatitude),
                                        as.numeric(gps_data$gpsLongitude),
                                        distance = 100, # 100 meters from shore
                                        shape = NULL) # Using the default Natural Earth 1:10m Land Polygon

print(gps_data)
```
For more accurate determination, a detailed coastline .shp file may be required (e.g. the [EEA Coastline Polygon](https://www.eea.europa.eu/data-and-maps/data/eea-coastline-for-analysis-2/gis-data/eea-coastline-polygon)). Refer to the help pages of `ifcb_is_near_land` for further information.

## Annotated Files

### Count and Summarize Annotated Image Data

#### PNG Directory

Summarize counts of annotated images at the sample and class levels. The 'hdr_folder' can be included to add GPS positions to the sample data frame:
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

Count the annotations in the MATLAB files, similar to `ifcb_summarize_png_data`:
```r
mat_count <- ifcb_count_mat_annotations(manual_folder = "data/manual",
                                        class2use_file = "data/config/class2use.mat",
                                        skip_class = "unclassified") # Or class ID

print(mat_count)
```

### Run Image Gallery

To visually inspect and correct annotations, run the image gallery. 
```r
ifcb_run_image_gallery()
```

![image_gallery](/man/figures/image_gallery.png)
Individual images can be selected and a list of selected images can be downloaded as a 'correction_file'. This file can be used to correct .mat annotations below using the `ifcb_correct_annotation` function.

### Correct .mat Files After Checking Images in the App

After reviewing images in the gallery, correct the .mat files using the 'correction file' with selected images:
```r
# Get class2use
class_name <- ifcb_get_mat_names("data/config/class2use.mat")
class2use <- ifcb_get_mat_variable("data/config/class2use.mat",
                                   variable_name = class_name)

# Find the class id of unclassified
unclassified_id <- which(grepl("unclassified",
                         class2use))

# ifcb_py_install(envname = ".virtualenvs/iRfcb") # If not already initialized

ifcb_correct_annotation(manual_folder = "data/manual",
                        out_folder = "data/manual",
                        correction_file = "data/Alexandrium_pseudogonyaulax_selected_images.txt",
                        correct_classid = unclassified_id)
```

### Replace Specific Class Annotations

Replace all instances of a specific class with "unclassified" (class id 1):
```r
# Get class2use
class_name <- ifcb_get_mat_names("data/config/class2use.mat")
class2use <- ifcb_get_mat_variable("data/config/class2use.mat",
                                   variable_name = class_name)

# Find the class id of Alexandrium_pseudogonyaulax
ap_id <- which(grepl("Alexandrium_pseudogonyaulax",
                     class2use))

# Find the class id of unclassified
unclassified_id <- which(grepl("unclassified",
                         class2use))

# ifcb_py_install(envname = ".virtualenvs/iRfcb") # If not already initialized

# Move all Alexandrium_pseudogonyaulax images to unclassified
ifcb_replace_mat_values(manual_folder = "data/manual",
                        out_folder = "data/manual",
                        target_id = ap_id,
                        new_id = unclassified_id)
```

### Extract Annotated Images

Extract annotated images, skipping the "unclassified" (class id 1) category:
```r
ifcb_extract_annotated_images(manual_folder = "data/manual",
                              class2use_file = "data/config/class2use.mat",
                              roi_folder = "data/data",
                              out_folder = "data/extracted_images",
                              skip_class = 1) # or "unclassified"
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

Prepare the PNG directory for publication as a zip-archive, similar to the files in the [SMHI IFCB Plankton image reference library](https://doi.org/10.17044/scilifelab.25883455):
```r
ifcb_zip_pngs(png_folder = "data/extracted_images",
              zip_filename = "zip/smhi_ifcb_skagerrak_kattegat_annotated_images_corrected.zip",
              readme_file = system.file("exdata/README-template.md", package = "iRfcb"), # Template icluded in `iRfcb`
              email_address = "tutorial@test.com",
              version = "1.1")
```


### MATLAB Directory

Prepare the MATLAB directory for publication as a zip-archive, similar to the files in the [SMHI IFCB Plankton image reference library](https://doi.org/10.17044/scilifelab.25883455):
```r
ifcb_zip_matlab(
  manual_folder = "data/manual",
  features_folder = "data/features",
  class2use_file = "data/config/class2use.mat",
  zip_filename = "zip/smhi_ifcb_skagerrak_kattegat_matlab_files_corrected.zip",
  data_folder = "data/data",
  readme_file = system.file("exdata/README-template.md", package = "iRfcb"), # Template icluded in `iRfcb`
  matlab_readme_file = system.file("exdata/MATLAB-template.md", package = "iRfcb"), # Template icluded in `iRfcb`
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
filenames <- c("D20230314T001205_IFCB134",
               "D20230615T123045_IFCB135")
timestamps <- ifcb_convert_filenames(filenames)
print(timestamps)
```

With ROI numbers:
```
filenames <- c("D20230314T001205_IFCB134_00023.png",
               "D20230615T123045_IFCB135")
timestamps <- ifcb_convert_filenames(filenames)
print(timestamps)
```

### Get Volume Analyzed in ml

Get the volume analyzed from header/adc files:
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
#### NOTE: These two steps require .mat files generated by the MATLAB package [ifcb-analysis](https://github.com/hsosik/ifcb-analysis) (Sosik and Olson 2007)

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

## References
- Hayashi, K., Walton, J., Lie, A., Smith, J. and Kudela M. Using particle size distribution (PSD) to automate imaging flow cytobot (IFCB) data quality in coastal California, USA. In prep.
- Sosik, H. M. and Olson, R. J. (2007) Limnol. Oceanogr: Methods 5, 204–216.
