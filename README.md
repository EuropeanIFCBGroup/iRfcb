[![R-CMD-check](https://github.com/anderstorstensson/iRfcb/actions/workflows/r-cmd-check.yml/badge.svg?event=push)](https://github.com/anderstorstensson/iRfcb/actions/workflows/r-cmd-check.yml)
# I are FlowCytobot (iRfcb): Functions for working with IFCB data in R

This package provides a set of functions to facilitate the analysis of IFCB (Imaging FlowCytobot) data. The functions allow for the conversion of filenames, creation of manifests, extraction of header and image data, summarization of images by class, and more. The primary goal is to streamline the workflow for researchers working with IFCB data.

## Installation

You can install the package from GitHub using the `devtools` package:

```r
# install.packages("devtools")
devtools::install_github("anderstorstensson/iRfcb")
```

## Functions

The package includes the following functions:

1. **ifcb_convert_filenames**: Convert filenames to a standardized format.
2. **ifcb_create_manifest**: Create a manifest file listing all files in specified paths.
3. **ifcb_extract_hdr_data**: Extract header data from .hdr files.
4. **ifcb_extract_pngs_from_roi**: Extract PNG images from ROI files.
5. **ifcb_extract_taxa_images**: Extract taxa images from classified sample files.
6. **ifcb_get_images_from_roi**: Retrieve images from ROI files.
7. **ifcb_get_mat_classes**: Get classes from .mat files.
8. **ifcb_get_mat_variables**: Retrieve variables from .mat files.
9. **ifcb_read_hdr**: Read .hdr files and extract relevant information.
10. **ifcb_read_mat_summary**: Read summary information from .mat files.
11. **ifcb_summarize_images_by_class**: Summarize images by class from .mat files.
12. **ifcb_volume_analyzed_from_adc**: Calculate volume analyzed from .adc files.
13. **ifcb_volume_analyzed**: Calculate volume analyzed.
14. **ifcb_zip_matlab**: Zip .mat files.
15. **ifcb_zip_pngs**: Zip PNG images.

## Examples

Here are some examples of how to use the functions in this package:

### Create a Manifest

```r
# Define the paths to include in the manifest
paths <- c("path/to/folder1", "path/to/file1.mat")

# Create the manifest file
ifcb_create_manifest(paths, manifest_path = "MANIFEST.txt", temp_dir = "temp")
```

### Extract Header Data

```r
# Define the path to the .hdr file
hdr_file <- "path/to/file.hdr"

# Extract the header data
header_data <- ifcb_extract_hdr_data(hdr_file)
print(header_data)
```

### Extract PNG Images from ROI

```r
# Define the sample and directories
sample <- "D20230311T092911"
classifieddir <- "path/to/classifieddir"
roidir <- "path/to/roidir"
outdir <- "path/to/outputdir"

# Extract PNG images from ROI
ifcb_extract_pngs_from_roi(sample, classifieddir, roidir, outdir)
```

### Extract Taxa Images

```r
# Define the parameters
sample <- "D20230311T092911"
classifieddir <- "path/to/classifieddir"
roidir <- "path/to/roidir"
outdir <- "path/to/outputdir"
taxa <- "All"  # or specify a particular taxa
threshold <- "opt"  # or specify another threshold

# Extract taxa images from the classified sample
ifcb_extract_taxa_images(sample, classifieddir, roidir, outdir, taxa, threshold)
```

## Repository

For more details and the latest updates, visit the [GitHub repository](https://github.com/anderstorstensson/iRfcb).

## License

This package is licensed under the MIT License.
