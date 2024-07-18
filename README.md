[![R-CMD-check](https://github.com/anderstorstensson/iRfcb/actions/workflows/r-cmd-check.yml/badge.svg?event=push)](https://github.com/anderstorstensson/iRfcb/actions/workflows/r-cmd-check.yml)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.12533225.svg)](https://doi.org/10.5281/zenodo.12533225)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

# I 'R' FlowCytobot: Tools for analyzing and processing data from the Imaging FlowCytobot (IFCB) using R

The `iRfcb` R package provides tools for working with Imaging FlowCytobot (IFCB) data, including quality control, particle size distribution analysis, and handling of annotated image data. This package facilitates the processing, analysis, and preparation of IFCB images and data for publication. The primary goal is to streamline the workflow for researchers working with IFCB data, and especially useful for someone who is using, or partly using, the MATLAB [ifcb-analysis](https://github.com/hsosik/ifcb-analysis) package (Sosik and Olson 2007).

## Installation

You can install the package from GitHub using the `devtools` package:
```r
# install.packages("devtools")
devtools::install_github("EuropeanIFCBGroup/iRfcb", 
                         dependencies = TRUE)
```
Some functions in `iRfcb` require `Python` to be installed (see in the sections below). You can download `Python` from the official website: [python.org/downloads](https://www.python.org/downloads/).

## Getting Started

Load the `iRfcb` library:
```r
library(iRfcb)
```

## Download Sample Data

To get started, download sample data from the [SMHI IFCB Plankton image reference library](https://doi.org/10.17044/scilifelab.25883455) with the following function:
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
                output_file = NULL,
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

# Plot PSD of the first sample
plot <- ifcb_psd_plot(sample_name = psd$data$sample[1],
                      data = psd$data,
                      fits = psd$fits,
                      start_fit = 10)
                      
print(plot)
```

### Check if IFCB is Near Land

To determine if the Imaging FlowCytobot (IFCB) is near land (i.e. in harbor), examine the position data in the .hdr files (or from other vectors of latitudes and longitudes):
```r
# Read HDR data and extract GPS position (when available)
gps_data <- ifcb_read_hdr_data("data/data/",
                               gps_only = TRUE)

gps_data$near_land <- ifcb_is_near_land(gps_data$gpsLatitude,
                                        gps_data$gpsLongitude,
                                        distance = 100, # 100 meters from shore
                                        shape = NULL) # Using the default NE 1:10m Land Polygon

print(gps_data)
```
For more accurate determination, a detailed coastline .shp file may be required (e.g. the [EEA Coastline Polygon](https://www.eea.europa.eu/data-and-maps/data/eea-coastline-for-analysis-2/gis-data/eea-coastline-polygon)). Refer to the help pages of `ifcb_is_near_land` for further information.

### Check which sub-basin an IFCB sample is from

To identify the specific sub-basin of the Baltic Sea (or using a custom shape-file) from which an Imaging FlowCytobot (IFCB) sample was collected, analyze the position data:
```r
# Define example latitude and longitude vectors
latitudes <- c(55.337, 54.729, 56.311, 57.975)
longitudes <- c(12.674, 14.643, 12.237, 10.637)

# Check in which Baltic sea basin the points are in
points_in_the_baltic <- ifcb_which_basin(latitudes, 
                                         longitudes, 
                                         shape_file = NULL)
print(points_in_the_baltic)

# Plot the points and the basins
ifcb_which_basin(latitudes, 
                 longitudes, 
                 plot = TRUE, 
                 shape_file = NULL)
```
This function reads a pre-packaged shapefile of the Baltic Sea, Kattegat, and Skagerrak basins from the 'iRfcb' package by default, or a user-supplied shapefile if provided. The shapefiles provided in 'iRfcb' originate from [SHARK](https://sharkweb.smhi.se/hamta-data/). 

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
                        correction_file = "data/manual/correction/Alexandrium_pseudogonyaulax_selected_images.txt",
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
              readme_file = system.file("exdata/README-template.md", 
                                        package = "iRfcb"), # Template icluded in `iRfcb`
              email_address = "tutorial@test.com",
              version = "1.1")
```


### MATLAB Directory

Prepare the MATLAB directory for publication as a zip-archive, similar to the files in the [SMHI IFCB Plankton image reference library](https://doi.org/10.17044/scilifelab.25883455):
```r
ifcb_zip_matlab(manual_folder = "data/manual",
                features_folder = "data/features",
                class2use_file = "data/config/class2use.mat",
                zip_filename = "zip/smhi_ifcb_skagerrak_kattegat_matlab_files_corrected.zip",
                data_folder = "data/data",
                readme_file = system.file("exdata/README-template.md", 
                                          package = "iRfcb"), # Template icluded in `iRfcb`
                matlab_readme_file = system.file("exdata/MATLAB-template.md", 
                                                 package = "iRfcb"), # Template icluded in `iRfcb`
                email_address = "tutorial@test.com",
                version = "1.1")
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
```r
filenames <- c("D20230314T001205_IFCB134",
               "D20230615T123045_IFCB135")
timestamps <- ifcb_convert_filenames(filenames)
print(timestamps)
```

With ROI numbers:
```r
filenames <- c("D20230314T001205_IFCB134_00023.png",
               "D20230615T123045_IFCB135")
timestamps <- ifcb_convert_filenames(filenames)
print(timestamps)
```

### Get Volume Analyzed in ml

Get the volume analyzed from header/adc files:
```r
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

### Check whether a class name is a diatom

This function takes a list of taxa names, cleans them, retrieves their corresponding classification records from the World Register of Marine Species (WoRMS), and checks if they belong to the specified diatom class. The function only uses the first name (genus name) of each taxa for classification. This function can be useful for converting biovolumes to carbon according to Menden-Deuer and Lessard 2000. See `iRfcb:::vol2C_nondiatom` and `iRfcb:::vol2C_lgdiatom` for carbon calculations (not included in NAMESPACE).

```r
class2use <- ifcb_get_mat_variable("data/config/class2use.mat")
               
data.frame(class2use,
           is_diatom = ifcb_is_diatom(class2use))
```
The default class for diatoms is defined as Bacillariophyceae, but may be adjusted using the `diatom_class` argument.

### Find trophic type of plankton taxa

This function takes a list of taxa names and matches them with the `SMHI Trophic Type` list used in [SHARK](https://sharkweb.smhi.se/hamta-data/).

```r
taxa_list <- c("Acanthoceras zachariasii",
               "Nodularia spumigena",
               "Acanthoica quattrospina",
               "Noctiluca",
               "Gymnodiniales")

ifcb_get_trophic_type(taxa_list)
```

### Check whether the positions are within the Baltic Sea or elsewhere

This check is useful if only you want to apply a classifier specifically to phytoplankton from the Baltic Sea.

```r
# Define example latitude and longitude vectors
latitudes <- c(55.337, 54.729, 56.311, 57.975)
longitudes <- c(12.674, 14.643, 12.237, 10.637)

# Check if the points are in the Baltic Sea Basin
points_in_the_baltic <- ifcb_is_in_basin(latitudes, longitudes)
print(points_in_the_baltic)

# Plot the points and the basin
ifcb_is_in_basin(latitudes, longitudes, plot = TRUE)
```

This function reads a land-buffered shapefile of the Baltic Sea Basin (including Öresund) from the 'iRfcb' package by default, or a user-supplied shapefile if provided.

### Find missing positions from RV Svea Ferrybox

This function is used by SMHI to collect and match stored ferrybox positions when they are not available in the .hdr files.

```r
# Define path where ferrybox data are located
ferrybox_folder <- "data/ferrybox_data"
timestamps <- as.POSIXct(c("2016-08-10 10:47:34 UTC",
                           "2016-08-10 11:12:21 UTC",
                           "2016-08-10 11:35:59 UTC"))

result <- ifcb_get_svea_position(timestamps, ferrybox_folder)
print(result)
```

### Get the column names needed for a data delivery to SHARK

This function is used by SMHI to map IFCB data into the [SHARK](https://sharkweb.smhi.se/hamta-data/) standard data delivery format.

```r
shark_colnames <- ifcb_get_shark_colnames()

print(shark_colnames)
```

## Working with Classified Results from MATLAB

### Extract Classified Results from a Sample
#### NOTE: These steps require .mat and .csv files generated by the MATLAB package [ifcb-analysis](https://github.com/hsosik/ifcb-analysis) (Sosik and Olson 2007)

Extract classified results from a sample:

```r
ifcb_extract_classified_images(sample = "D20230810T113059_IFCB134",
                               classified_folder = "data/classified/2023",
                               roi_folder = "data/data",
                               out_folder = "data/classified_images",
                               taxa = "All", # or specify a particular taxa
                               threshold = "opt") # or specify another threshold
```

### Read feature data

Read all feature files (.csv) from a folder:

```r
# Read feature files from a folder
features <- ifcb_read_features("data/features/2023")

# Read only multiblob feature files
multiblob_features <- ifcb_read_features("data/features/2023", multiblob = TRUE)
```

### Read a Summary File

Read a summary file:

```r
summary_data <- ifcb_read_summary("data/classified/2023/summary/summary_allTB_2023.mat",
                                  biovolume = TRUE,
                                  threshold = "opt")
```

### Summarize counts, biovolumes and carbon content from classified IFCB data

This function calculates aggregated biovolumes and carbon content from Imaging FlowCytobot (IFCB) samples based on feature and MATLAB classification result files, without summarizing the data in MATLAB. Biovolumes are converted to carbon according to Menden-Deuer and Lessard 2000 for individual regions of interest (ROI), where different conversion factors are applied to diatoms and non-diatom protist. If provided, it also incorporates sample volume data from HDR files to compute biovolume and carbon content per liter of sample. See details in the help pages for `ifcb_summarize_biovolumes` and `ifcb_extract_biovolumes`.

```r
# Summarize biovolume data using IFCB data from the specified folders
biovolume_data <- ifcb_summarize_biovolumes(feature_folder = "data/features/2023",
                                            class_folder = "data/classified/2023",
                                            hdr_folder = "data/data/2023",
                                            micron_factor = 1/3.4,
                                            diatom_class = "Bacillariophyceae",
                                            threshold = "opt")
```

This concludes the tutorial for the `iRfcb` package. For more detailed information, refer to the package documentation. Happy analyzing!

## Repository

For more details and the latest updates, visit the [GitHub repository](https://github.com/anderstorstensson/iRfcb).

## License

This package is licensed under the MIT License.

## References
- Hayashi, K., Walton, J., Lie, A., Smith, J. and Kudela M. Using particle size distribution (PSD) to automate imaging flow cytobot (IFCB) data quality in coastal California, USA. In prep.
- Menden-Deuer Susanne, Lessard Evelyn J., (2000), Carbon to volume relationships for dinoflagellates, diatoms, and other protist plankton, Limnology and Oceanography, 3, doi: 10.4319/lo.2000.45.3.0569.
- Sosik, H. M. and Olson, R. J. (2007) Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnol. Oceanogr: Methods 5, 204–216.
