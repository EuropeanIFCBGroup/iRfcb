# iRfcb Introduction

## Introduction

The `iRfcb` package is an open-source R package designed to streamline
the analysis of Imaging FlowCytobot (IFCB) data, with a focus on
supporting marine ecological research and monitoring. By integrating R
and Python functionalities, the package facilitates efficient handling
and sharing of IFCB image data, extraction of key metadata, and
preparation of outputs for further taxonomic, ecological, or spatial
analyses.

This tutorial serves as an introduction to the core functionalities of
`iRfcb`, providing step-by-step instructions for data preprocessing,
taxonomic analysis, and SHARK-compliant data export. For additional
guides—such as quality control of IFCB data, data sharing, and
integration with MATLAB—please refer to the other tutorials available on
the project’s [webpage](https://europeanifcbgroup.github.io/iRfcb/).

## Getting Started

### Installation

You can install the package from CRAN using:

``` r
install.packages("iRfcb")
```

Load the `iRfcb` and `dplyr` libraries:

``` r
library(iRfcb)
```

### Download Sample Data

To get started, download sample data from the [SMHI IFCB Plankton Image
Reference Library](https://doi.org/10.17044/scilifelab.25883455.v3)
(Torstensson et al. 2024) with the following function:

``` r
# Define data directory
data_dir <- "data"

# Download and extract test data in the data folder
ifcb_download_test_data(dest_dir = data_dir)
```

## Extract IFCB Data

This section demonstrates a selection of general data extraction tools
available in `iRfcb`.

### Extract Timestamps from IFCB Sample Filenames

Extract timestamps from sample names or filenames:

``` r
# Example sample names
filenames <- list.files("data/data/2023/D20230314", recursive = TRUE)

# Print filenames
print(filenames)
```

    ## [1] "D20230314T001205_IFCB134.adc" "D20230314T001205_IFCB134.hdr"
    ## [3] "D20230314T001205_IFCB134.roi" "D20230314T003836_IFCB134.adc"
    ## [5] "D20230314T003836_IFCB134.hdr" "D20230314T003836_IFCB134.roi"

``` r
# Convert filenames to timestamps
timestamps <- ifcb_convert_filenames(filenames)

# Print result
print(timestamps)
```

    ## # A tibble: 6 × 8
    ##   sample     timestamp           date        year month   day time   ifcb_number
    ##   <chr>      <dttm>              <date>     <dbl> <dbl> <int> <time> <chr>      
    ## 1 D20230314… 2023-03-14 00:12:05 2023-03-14  2023     3    14 12'05" IFCB134    
    ## 2 D20230314… 2023-03-14 00:12:05 2023-03-14  2023     3    14 12'05" IFCB134    
    ## 3 D20230314… 2023-03-14 00:12:05 2023-03-14  2023     3    14 12'05" IFCB134    
    ## 4 D20230314… 2023-03-14 00:38:36 2023-03-14  2023     3    14 38'36" IFCB134    
    ## 5 D20230314… 2023-03-14 00:38:36 2023-03-14  2023     3    14 38'36" IFCB134    
    ## 6 D20230314… 2023-03-14 00:38:36 2023-03-14  2023     3    14 38'36" IFCB134

If the filename includes ROI numbers (e.g., in an extracted `.png`
image), a separate column, `roi`, will be added to the output.

``` r
# Example sample names
filenames <- list.files("data/png/Alexandrium_pseudogonyaulax_050")

# Print filenames
print(filenames)
```

    ## [1] "D20220712T210855_IFCB134_00042.png" "D20220712T210855_IFCB134_00164.png"
    ## [3] "D20220712T222710_IFCB134_00044.png"

``` r
# Convert filenames to timestamps
timestamps <- ifcb_convert_filenames(filenames)

# Print result
print(timestamps)
```

    ## # A tibble: 3 × 9
    ##   sample   timestamp           date        year month   day time     ifcb_number
    ##   <chr>    <dttm>              <date>     <dbl> <dbl> <int> <time>   <chr>      
    ## 1 D202207… 2022-07-12 21:08:55 2022-07-12  2022     7    12 21:08:55 IFCB134    
    ## 2 D202207… 2022-07-12 21:08:55 2022-07-12  2022     7    12 21:08:55 IFCB134    
    ## 3 D202207… 2022-07-12 22:27:10 2022-07-12  2022     7    12 22:27:10 IFCB134    
    ## # ℹ 1 more variable: roi <int>

### Calculate Volume Analyzed in ml

The analyzed volume of a sample can be calculated using data from `.hdr`
and `.adc` files.

``` r
# Path to HDR file
hdr_file <- "data/data/2023/D20230314/D20230314T001205_IFCB134.hdr"

# Calculate volume analyzed (in ml)
volume_analyzed <- ifcb_volume_analyzed(hdr_file)

# Print result
print(volume_analyzed)
```

    ## [1] 4.568676

### Get Sample Runtime

Get the runtime from a `.hdr` file:

``` r
# Get runtime from HDR-file
run_time <- ifcb_get_runtime(hdr_file)

# Print result
print(run_time)
```

    ## $runtime
    ## [1] 1200.853
    ## 
    ## $inhibittime
    ## [1] 104.3704

### Read Feature Data

Read all feature files (`.csv`) from a folder:

``` r
# Read feature files from a folder
features <- ifcb_read_features("data/features/2023/",
                               verbose = FALSE) # Do not print progress bar

# Print output from the first sample in the list
print(features[[1]])
```

    ## # A tibble: 1,218 × 237
    ##    roi_number  Area Biovolume BoundingBox_xwidth BoundingBox_ywidth ConvexArea
    ##         <dbl> <dbl>     <dbl>              <dbl>              <dbl>      <dbl>
    ##  1          2   446     6083.                 31                 21        542
    ##  2          3  4326   142783.                111                 63       5186
    ##  3          4  9739   336908.                202                129      10581
    ##  4          5   580     9187.                 27                 28        602
    ##  5          6  3927   120367.                 99                 50       4191
    ##  6          7   290     3112.                 22                 20        335
    ##  7          8  4437   183891.                 90                 62       4894
    ##  8          9   576     9297.                 27                 29        605
    ##  9         10   540     7712.                 28                 25        564
    ## 10         11   990    18779.                 53                 31       1197
    ## # ℹ 1,208 more rows
    ## # ℹ 231 more variables: ConvexPerimeter <dbl>, Eccentricity <dbl>,
    ## #   EquivDiameter <dbl>, Extent <dbl>, FeretDiameter <dbl>, H180 <dbl>,
    ## #   H90 <dbl>, Hflip <dbl>, MajorAxisLength <dbl>, MinorAxisLength <dbl>,
    ## #   Orientation <dbl>, Perimeter <dbl>, RWcenter2total_powerratio <dbl>,
    ## #   RWhalfpowerintegral <dbl>, Solidity <dbl>, moment_invariant1 <dbl>,
    ## #   moment_invariant2 <dbl>, moment_invariant3 <dbl>, …

``` r
# Read only multiblob feature files
multiblob_features <- ifcb_read_features("data/features/2023", 
                                         multiblob = TRUE,
                                         verbose = FALSE)

# Print output from the first sample in the list
print(multiblob_features[[1]])
```

    ## # A tibble: 26 × 22
    ##    roi_number blob_number  Area MajorAxisLength MinorAxisLength Eccentricity
    ##         <dbl>       <dbl> <dbl>           <dbl>           <dbl>        <dbl>
    ##  1        154           1  3647           110.             45.0        0.912
    ##  2        154           2  1626            77.5            30.7        0.918
    ##  3        214           1  7456           232.            123.         0.849
    ##  4        214           2  4840           102.             68.3        0.741
    ##  5        214           3   910            54.2            28.5        0.850
    ##  6        214           4   153            19.0            10.9        0.817
    ##  7        447           1 29964           808.             64.7        0.997
    ##  8        447           2   668            77.4            34.3        0.896
    ##  9        537           1  2989            65.1            59.1        0.419
    ## 10        537           2  2978            63.5            60.1        0.323
    ## # ℹ 16 more rows
    ## # ℹ 16 more variables: Orientation <dbl>, ConvexArea <dbl>,
    ## #   EquivDiameter <dbl>, Solidity <dbl>, Extent <dbl>, Perimeter <dbl>,
    ## #   ConvexPerimeter <dbl>, FeretDiameter <dbl>, BoundingBox_xwidth <dbl>,
    ## #   BoundingBox_ywidth <dbl>, shapehist_mean_normEqD <dbl>,
    ## #   shapehist_mode_normEqD <dbl>, shapehist_median_normEqD <dbl>,
    ## #   shapehist_skewness_normEqD <dbl>, shapehist_kurtosis_normEqD <dbl>, …

## Extract Images from ROI files

IFCB images stored in `.roi` files can be extracted as `.png` files
using the `iRfcb` package, as demonstrated below.

Extract all images from a sample using the
[`ifcb_extract_pngs()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_pngs.md)
function. You can specify the `out_folder`, but by default, images will
be saved in a subdirectory within the same directory as the ROI file.
The `gamma` can be adjusted to enhance image contrast, and an optional
scale bar can be added by specifying `scale_bar_um`.

``` r
# All ROIs in sample
ifcb_extract_pngs(
  "data/data/2023/D20230314/D20230314T001205_IFCB134.roi",
  gamma = 1, # Default gamma value
  scale_bar_um = 5 # Add a 5 micrometer scale bar
) 
```

    ## Writing 1218 ROIs from D20230314T001205_IFCB134.roi to data/data/2023/D20230314/D20230314T001205_IFCB134

Extract specific ROIs:

``` r
# Only ROI number 2 and 5
ifcb_extract_pngs("data/data/2023/D20230314/D20230314T003836_IFCB134.roi",
                  ROInumbers = c(2, 5))
```

    ## Writing 2 ROIs from D20230314T003836_IFCB134.roi to data/data/2023/D20230314/D20230314T003836_IFCB134

To extract annotated images or classified results from MATLAB files,
please see the `vignette("image-export-tutorial")` and
`vignette("matlab-tutorial")` tutorials.

## Classify IFCB Images

IFCB images can be classified directly in R using a CNN model served by
a [Gradio](https://www.gradio.app/) application. By default, the
classification functions use a public example Space hosted on Hugging
Face (`https://irfcb-classify.hf.space`). This Space has limited
resources and is intended for testing and demonstration purposes. For
large-scale or production classification, we recommend deploying your
own instance of the [IFCB Classification
App](https://github.com/EuropeanIFCBGroup/ifcb-inference-app) with your
own model and passing its URL via the `gradio_url` argument.

### Available Models

Use
[`ifcb_classify_models()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_models.md)
to list the CNN models available on the Gradio server:

``` r
ifcb_classify_models()
```

### Classify All Images in a Sample

[`ifcb_classify_sample()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_sample.md)
extracts images from a `.roi` file internally and returns predictions
without requiring a separate extraction step:

``` r
# Classify all images in a sample
results <- ifcb_classify_sample(
  "data/data/2023/D20230314/D20230314T001205_IFCB134.roi",
  verbose = FALSE
)

# Print result
print(results)
```

### Classify Pre-extracted PNG Images

If images have already been extracted, pass a vector of PNG file paths
to
[`ifcb_classify_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_images.md):

``` r
# List extracted PNG files
png_files <- list.files(
  "data/data/2023/D20230314/D20230314T001205_IFCB134",
  pattern = "\\.png$",
  full.names = TRUE
)

# Classify images
results <- ifcb_classify_images(png_files, verbose = FALSE)

# Print result
print(results)
```

Both functions return a data frame with `file_name`, `class_name`,
`class_name_auto`, `score`, and `model_name` columns, and query the
Gradio API at `https://irfcb-classify.hf.space` by default. Per-class F2
optimal thresholds are always applied: `class_name` contains the
threshold-applied classification (labeled `"unclassified"` when below
threshold), while `class_name_auto` contains the winning class without
any threshold. The `top_n` argument controls how many top predictions
are returned per image, and `model_name` specifies which CNN model to
use (default: `"SMHI NIVA ResNet50 V5"`).

### Save Classification Results

[`ifcb_save_classification()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_save_classification.md)
classifies all images in a `.roi` file and saves the full score matrix.
Three output formats are supported via the `format` argument:

``` r
# HDF5 (default) - IFCB Dashboard v3 format (requires hdf5r package)
ifcb_save_classification(
  "data/data/2023/D20230314/D20230314T001205_IFCB134.roi",
  output_folder = "output"
)
# Creates: output/D20230314T001205_IFCB134_class.h5

# MAT - IFCB Dashboard v1 format (requires Python with scipy)
ifcb_save_classification(
  "data/data/2023/D20230314/D20230314T001205_IFCB134.roi",
  output_folder = "output",
  format = "mat"
)
# Creates: output/D20230314T001205_IFCB134_class_v1.mat

# CSV - ClassiPyR-compatible format
ifcb_save_classification(
  "data/data/2023/D20230314/D20230314T001205_IFCB134.roi",
  output_folder = "output",
  format = "csv"
)
# Creates: output/D20230314T001205_IFCB134.csv
```

The output file contains `output_scores` (N x C matrix), `class_labels`,
`roi_numbers`, per-class `thresholds`, and
`class_labels_above_threshold`.

## Taxonomical Data

Maintaining up-to-date taxonomic data is essential for ensuring accurate
species names and classifications, which directly impact calculations
like carbon concentrations in `iRfcb`.

Up-to-date taxonomy also ensures data harmonization by preventing issues
like misspellings, outdated synonyms, or inconsistent classifications.
This consistency is crucial for integrating and comparing datasets
across studies, regions, and time periods, improving the reliability of
scientific outcomes.

### Taxon matching with WoRMS

Taxonomic names can be matched against the [World Register of Marine
Species (WoRMS)](https://www.marinespecies.org/), ensuring accuracy and
consistency. The `iRfcb` package includes a built-in function for taxon
matching via the WoRMS API, featuring a retry mechanism to handle server
errors, making it particularly useful for automated data pipelines. For
additional tools and functionality, the R package
[`worrms`](https://cran.r-project.org/package=worrms) provides a
comprehensive suite of options for interacting with the WoRMS database.

``` r
# Example taxa names
taxa_names <- c("Alexandrium_pseudogonyaulax", "Guinardia_delicatula")

# Retrieve WoRMS records
worms_records <- ifcb_match_taxa_names(taxa_names, 
                                       verbose = FALSE) # Do not print progress bar

# Print result
print(worms_records)
```

    ## # A tibble: 2 × 29
    ##   name  AphiaID url   scientificname authority status unacceptreason taxonRankID
    ##   <chr>   <int> <chr> <chr>          <chr>     <chr>  <lgl>                <int>
    ## 1 Alex…  109713 http… Alexandrium p… (Biechel… accep… NA                     220
    ## 2 Guin…  149112 http… Guinardia del… (Cleve) … unass… NA                     220
    ## # ℹ 21 more variables: rank <chr>, valid_AphiaID <int>, valid_name <chr>,
    ## #   valid_authority <chr>, parentNameUsageID <int>, originalNameUsageID <int>,
    ## #   kingdom <chr>, phylum <chr>, class <chr>, order <chr>, family <chr>,
    ## #   genus <chr>, citation <chr>, lsid <chr>, isMarine <int>, isBrackish <lgl>,
    ## #   isFreshwater <int>, isTerrestrial <int>, isExtinct <int>, match_type <chr>,
    ## #   modified <chr>

### Check whether a class name is a diatom

This function takes a list of taxa names, cleans them, retrieves their
corresponding classification records from WoRMS, and checks if they
belong to the specified diatom class. The function only uses the first
name (genus name) of each taxa for classification. This function can be
useful for converting biovolumes to carbon according to Menden-Deuer and
Lessard (2000). See
[`vol2C_nondiatom()`](https://europeanifcbgroup.github.io/iRfcb/reference/vol2C_nondiatom.md)
and
[`vol2C_lgdiatom()`](https://europeanifcbgroup.github.io/iRfcb/reference/vol2C_lgdiatom.md)
for carbon calculations (not included in NAMESPACE).

``` r
# Read class2use file and select five taxa
class2use <- ifcb_get_mat_variable("data/config/class2use.mat")[10:15]

# Create a dataframe with class name and result from `ifcb_is_diatom`
class_list <- data.frame(class2use,
                         is_diatom = ifcb_is_diatom(class2use, verbose = FALSE))

# Print rows 10-15 of result
print(class_list)
```

    ##                    class2use is_diatom
    ## 1        Nodularia_spumigena     FALSE
    ## 2            Cryptomonadales     FALSE
    ## 3    Acanthoica_quattrospina     FALSE
    ## 4 Asterionellopsis_glacialis      TRUE
    ## 5                  Centrales      TRUE
    ## 6            Centrales_chain      TRUE

The default class for diatoms is defined as Bacillariophyceae, but may
be adjusted using the `diatom_class` argument.

### Find trophic type of plankton taxa

This function takes a list of taxa names and matches them with the
**SMHI Trophic Type** list used in [SHARK](https://shark.smhi.se/en/).

``` r
# Example taxa names
taxa_list <- c(
  "Acanthoceras zachariasii",
  "Nodularia spumigena",
  "Acanthoica quattrospina",
  "Noctiluca",
  "Gymnodiniales"
)

# Get trophic type for taxa
trophic_type <- ifcb_get_trophic_type(taxa_list)

# Print result
print(trophic_type)
```

    ## [1] "AU" "AU" "MX" "HT" "NS"

## SHARK export

This function is used by SMHI to map IFCB data into the
[SHARK](https://shark.smhi.se/hamta-data/) standard data delivery
format. An example submission is also provided in `iRfcb`.

``` r
# Get column names from example
shark_colnames <- ifcb_get_shark_colnames()

# Print column names
print(shark_colnames)
```

    ## # A tibble: 0 × 67
    ## # ℹ 67 variables: MYEAR <dbl>, STATN <chr>, SAMPLING_PLATFORM <chr>,
    ## #   PROJ <chr>, ORDERER <chr>, SHIPC <chr>, CRUISE_NO <dbl>, DATE_TIME <dbl>,
    ## #   SDATE <date>, STIME <time>, TIMEZONE <chr>, LATIT <dbl>, LONGI <dbl>,
    ## #   POSYS <chr>, WADEP <lgl>, MPROG <chr>, MNDEP <dbl>, MXDEP <dbl>,
    ## #   SLABO <chr>, ACKR_SMP <chr>, SMTYP <chr>, PDMET <chr>, SMVOL <dbl>,
    ## #   METFP <chr>, IFCBNO <chr>, SMPNO <chr>, LATNM <chr>, SFLAG <chr>,
    ## #   LATNM_SFLAG <chr>, TRPHY <chr>, APHIA_ID <dbl>, IMAGE_VERIFICATION <chr>, …

``` r
# Load example stored from `iRfcb`
shark_example <- ifcb_get_shark_example()

# Print the SHARK data submission example
print(shark_example)
```

    ## # A tibble: 5 × 67
    ##   MYEAR STATN          SAMPLING_PLATFORM PROJ  ORDERER SHIPC CRUISE_NO DATE_TIME
    ##   <dbl> <chr>          <chr>             <chr> <chr>   <chr>     <dbl> <chr>    
    ## 1  2022 RV_FB_D202207… IFCB              IFCB… SMHI    77SE         12 2.02e+15 
    ## 2  2022 RV_FB_D202207… IFCB              IFCB… SMHI    77SE         12 2.02e+15 
    ## 3  2022 RV_FB_D202207… IFCB              IFCB… SMHI    77SE         12 2.02e+15 
    ## 4  2022 RV_FB_D202207… IFCB              IFCB… SMHI    77SE         12 2.02e+15 
    ## 5  2022 RV_FB_D202207… SveaFB            IFCB… SMHI    77SE         12 2.02e+15 
    ## # ℹ 59 more variables: SDATE <date>, STIME <time>, TIMEZONE <chr>, LATIT <dbl>,
    ## #   LONGI <dbl>, POSYS <chr>, WADEP <lgl>, MPROG <chr>, MNDEP <dbl>,
    ## #   MXDEP <dbl>, SLABO <chr>, ACKR_SMP <chr>, SMTYP <chr>, PDMET <chr>,
    ## #   SMVOL <dbl>, METFP <chr>, IFCBNO <chr>, SMPNO <chr>, LATNM <chr>,
    ## #   SFLAG <chr>, LATNM_SFLAG <chr>, TRPHY <chr>, APHIA_ID <dbl>,
    ## #   IMAGE_VERIFICATION <chr>, VERIFIED_BY <lgl>, COUNT <dbl>, ABUND <dbl>,
    ## #   BIOVOL <dbl>, C_CONC <dbl>, QFLAG <lgl>, COEFF <dbl>, CLASS_NAME <chr>, …

This concludes this tutorial for the `iRfcb` package. For additional
guides—such as quality control of IFCB data, data sharing, and
integration with MATLAB—please refer to the other tutorials available on
the project’s [webpage](https://europeanifcbgroup.github.io/iRfcb/). See
how data pipelines can be constructed using `iRfcb` in the following
[Example Project](https://github.com/nodc-sweden/ifcb-data-pipeline).
Happy analyzing!

## Citation

    ## To cite package 'iRfcb' in publications use:
    ## 
    ##   Anders Torstensson (2026). iRfcb: Tools for Managing Imaging
    ##   FlowCytobot (IFCB) Data. R package version 0.8.1.
    ##   https://CRAN.R-project.org/package=iRfcb
    ## 
    ## A BibTeX entry for LaTeX users is
    ## 
    ##   @Manual{,
    ##     title = {iRfcb: Tools for Managing Imaging FlowCytobot (IFCB) Data},
    ##     author = {Anders Torstensson},
    ##     year = {2026},
    ##     note = {R package version 0.8.1},
    ##     url = {https://CRAN.R-project.org/package=iRfcb},
    ##   }

## References

- Torstensson, A., Skjevik, A-T., Mohlin, M., Karlberg, M. and
  Karlson, B. (2024). SMHI IFCB Plankton Image Reference Library.
  SciLifeLab. Dataset. <https://doi.org/10.17044/scilifelab.25883455.v3>
