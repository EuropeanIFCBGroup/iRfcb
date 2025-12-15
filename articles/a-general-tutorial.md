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
library(dplyr) # For data wrangling
```

### Download Sample Data

To get started, download sample data from the [SMHI IFCB Plankton Image
Reference Library](https://doi.org/10.17044/scilifelab.25883455.v3)
(Torstensson et al. 2024) with the following function:

``` r
# Define data directory
data_dir <- "data"

# Download and extract test data in the data folder
ifcb_download_test_data(dest_dir = data_dir,
                        max_retries = 10,
                        sleep_time = 30)
```

    ## Download and extraction complete.

## Extract IFCB Data

This section demonstrates a selection of general data extraction tools
available in `iRfcb`.

### Extract Timestamps from IFCB sample Filenames

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

    ##                     sample           timestamp       date year month day
    ## 1 D20230314T001205_IFCB134 2023-03-14 00:12:05 2023-03-14 2023     3  14
    ## 2 D20230314T001205_IFCB134 2023-03-14 00:12:05 2023-03-14 2023     3  14
    ## 3 D20230314T001205_IFCB134 2023-03-14 00:12:05 2023-03-14 2023     3  14
    ## 4 D20230314T003836_IFCB134 2023-03-14 00:38:36 2023-03-14 2023     3  14
    ## 5 D20230314T003836_IFCB134 2023-03-14 00:38:36 2023-03-14 2023     3  14
    ## 6 D20230314T003836_IFCB134 2023-03-14 00:38:36 2023-03-14 2023     3  14
    ##       time ifcb_number
    ## 1 00:12:05     IFCB134
    ## 2 00:12:05     IFCB134
    ## 3 00:12:05     IFCB134
    ## 4 00:38:36     IFCB134
    ## 5 00:38:36     IFCB134
    ## 6 00:38:36     IFCB134

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

    ##                     sample           timestamp       date year month day
    ## 1 D20220712T210855_IFCB134 2022-07-12 21:08:55 2022-07-12 2022     7  12
    ## 2 D20220712T210855_IFCB134 2022-07-12 21:08:55 2022-07-12 2022     7  12
    ## 3 D20220712T222710_IFCB134 2022-07-12 22:27:10 2022-07-12 2022     7  12
    ##       time ifcb_number roi
    ## 1 21:08:55     IFCB134  42
    ## 2 21:08:55     IFCB134 164
    ## 3 22:27:10     IFCB134  44

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

# Print output of first 10 columns from the first sample in the list
head(features[[1]])[,1:10]
```

    ##   roi_number Area  Biovolume BoundingBox_xwidth BoundingBox_ywidth ConvexArea
    ## 1          2  446   6082.909                 31                 21        542
    ## 2          3 4326 142783.030                111                 63       5186
    ## 3          4 9739 336908.323                202                129      10581
    ## 4          5  580   9186.802                 27                 28        602
    ## 5          6 3927 120366.981                 99                 50       4191
    ## 6          7  290   3111.748                 22                 20        335
    ##   ConvexPerimeter Eccentricity EquivDiameter    Extent
    ## 1        87.24196    0.6006111      23.82991 0.6850998
    ## 2       291.42030    0.8980639      74.21613 0.6186186
    ## 3       505.83898    0.9753657     111.35565 0.3737432
    ## 4        88.58696    0.3299815      27.17497 0.7671958
    ## 5       265.49548    0.9016151      70.71076 0.7933333
    ## 6        67.86613    0.3332706      19.21560 0.6590909

``` r
# Read only multiblob feature files
multiblob_features <- ifcb_read_features("data/features/2023", 
                                         multiblob = TRUE,
                                         verbose = FALSE)

# Print output of first 10 columns from the first sample in the list
head(multiblob_features[[1]])[,1:10]
```

    ##   roi_number blob_number Area MajorAxisLength MinorAxisLength Eccentricity
    ## 1        154           1 3647       109.93092        45.00010    0.9123779
    ## 2        154           2 1626        77.53922        30.74631    0.9180235
    ## 3        214           1 7456       232.11148       122.61037    0.8490956
    ## 4        214           2 4840       101.68493        68.30606    0.7407850
    ## 5        214           3  910        54.18655        28.51088    0.8503847
    ## 6        214           4  153        18.95031        10.93057    0.8168844
    ##   Orientation ConvexArea EquivDiameter  Solidity
    ## 1    11.28171       4205      68.14327 0.8673008
    ## 2    26.71876       2495      45.50041 0.6517034
    ## 3    30.89332      23666      97.43343 0.3150511
    ## 4   -35.88789       6955      78.50146 0.6959022
    ## 5    27.00911       1551      34.03892 0.5867182
    ## 6    48.78767        188      13.95728 0.8138298

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
please see the
[`vignette("image-export-tutorial")`](https://europeanifcbgroup.github.io/iRfcb/articles/image-export-tutorial.md)
and
[`vignette("matlab-tutorial")`](https://europeanifcbgroup.github.io/iRfcb/articles/matlab-tutorial.md)
tutorials.

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
tibble(worms_records)
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
class_list
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
**SMHI Trophic Type** list used in
[SHARK](https://shark.smhi.se/hamta-data/).

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

    ##  [1] MYEAR                  STATN                  SAMPLING_PLATFORM     
    ##  [4] PROJ                   ORDERER                SHIPC                 
    ##  [7] CRUISE_NO              DATE_TIME              SDATE                 
    ## [10] STIME                  TIMEZONE               LATIT                 
    ## [13] LONGI                  POSYS                  WADEP                 
    ## [16] MPROG                  MNDEP                  MXDEP                 
    ## [19] SLABO                  ACKR_SMP               SMTYP                 
    ## [22] PDMET                  SMVOL                  METFP                 
    ## [25] IFCBNO                 SMPNO                  LATNM                 
    ## [28] SFLAG                  LATNM_SFLAG            TRPHY                 
    ## [31] APHIA_ID               IMAGE_VERIFICATION     VERIFIED_BY           
    ## [34] COUNT                  ABUND                  BIOVOL                
    ## [37] C_CONC                 QFLAG                  COEFF                 
    ## [40] CLASS_NAME             CLASS_F1               UNCLASSIFIED_COUNTS   
    ## [43] UNCLASSIFIED_ABUNDANCE UNCLASSIFIED_VOLUME    METOA                 
    ## [46] ASSOCIATED_MEDIA       CLASSPROG              ALABO                 
    ## [49] ACKR_ANA               ANADATE                METDC                 
    ## [52] TRAINING_SET           CLASSIFIER_USED        MANUAL_QC_DATE        
    ## [55] PRE_FILTER_SIZE        PH_FB                  CHL_FB                
    ## [58] CDOM_FB                PHYC_FB                PHER_FB               
    ## [61] WATERFLOW_FB           TURB_FB                PCO2_FB               
    ## [64] TEMP_FB                PSAL_FB                OSAT_FB               
    ## [67] DOXY_FB               
    ## <0 rows> (or 0-length row.names)

``` r
# Load example stored from `iRfcb`
shark_example <- ifcb_get_shark_example()

# Print first ten columns of the SHARK data submission example
head(shark_example)[1:10]
```

    ##   MYEAR                  STATN SAMPLING_PLATFORM              PROJ ORDERER
    ## 1  2022 RV_FB_D20220713T175838              IFCB IFCB, DTO, JERICO    SMHI
    ## 2  2022 RV_FB_D20220713T175838              IFCB IFCB, DTO, JERICO    SMHI
    ## 3  2022 RV_FB_D20220713T175838              IFCB IFCB, DTO, JERICO    SMHI
    ## 4  2022 RV_FB_D20220713T175838              IFCB IFCB, DTO, JERICO    SMHI
    ## 5  2022 RV_FB_D20220713T175838            SveaFB IFCB, DTO, JERICO    SMHI
    ##   SHIPC CRUISE_NO DATE_TIME      SDATE    STIME
    ## 1  77SE        12  2,02E+13 2022-07-13 17:58:38
    ## 2  77SE        12  2,02E+13 2022-07-13 17:58:38
    ## 3  77SE        12  2,02E+13 2022-07-13 17:58:38
    ## 4  77SE        12  2,02E+13 2022-07-13 17:58:38
    ## 5  77SE        12  2,02E+13 2022-07-13 17:58:38

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
    ##   Anders Torstensson (2025). iRfcb: Tools for Managing Imaging
    ##   FlowCytobot (IFCB) Data. R package version 0.6.0.
    ##   https://CRAN.R-project.org/package=iRfcb
    ## 
    ## A BibTeX entry for LaTeX users is
    ## 
    ##   @Manual{,
    ##     title = {iRfcb: Tools for Managing Imaging FlowCytobot (IFCB) Data},
    ##     author = {Anders Torstensson},
    ##     year = {2025},
    ##     note = {R package version 0.6.0},
    ##     url = {https://CRAN.R-project.org/package=iRfcb},
    ##   }

## References

- Torstensson, A., Skjevik, A-T., Mohlin, M., Karlberg, M. and
  Karlson, B. (2024). SMHI IFCB Plankton Image Reference Library.
  SciLifeLab. Dataset. <https://doi.org/10.17044/scilifelab.25883455.v3>
