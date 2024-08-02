# I 'R' FlowCytobot: Tools for Analyzing and Processing Data from the Imaging FlowCytobot (IFCB)

[![R-CMD-check](https://github.com/EuropeanIFCBGroup/iRfcb/actions/workflows/r-cmd-check.yml/badge.svg?event=push)](https://github.com/EuropeanIFCBGroup/iRfcb/actions/workflows/r-cmd-check.yml)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.12533225.svg)](https://doi.org/10.5281/zenodo.12533225)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![Codecov test coverage](https://codecov.io/gh/EuropeanIFCBGroup/iRfcb/branch/main/graph/badge.svg)](https://app.codecov.io/gh/EuropeanIFCBGroup/iRfcb?branch=main)
[![CodeFactor](https://www.codefactor.io/repository/github/europeanifcbgroup/irfcb/badge)](https://www.codefactor.io/repository/github/europeanifcbgroup/irfcb)

## Overview

The `iRfcb` R package provides tools for working with Imaging FlowCytobot (IFCB) data, including quality control, particle size distribution analysis, and handling of annotated image data. This package facilitates the processing, analysis, and preparation of IFCB images and data for publication. It is especially useful for researchers using, or partly using, the MATLAB [ifcb-analysis](https://github.com/hsosik/ifcb-analysis) package.

### Key Features

- **Data Management**: Comprehensive functions for reading IFCB files, counting and summarizing annotated and classified image data, and correcting annotated data.
- **Quality Control**: Tools for analyzing particle size distribution and ensuring high data quality.
- **Geospatial Analysis**: Functions to determine if the IFCB is near land or within specific marine basins.
- **Image Extraction**: Tools to extract and prepare images for publication.
- **Image Gallery**: Interactive gallery for viewing and selecting IFCB images.
- **Taxonomical Data**: Tools for handling and analyzing taxonomic data and calculating biomass concentration from image data.

## Installation

You can install the package from GitHub using the `devtools` package:

```r
# install.packages("devtools")
devtools::install_github("EuropeanIFCBGroup/iRfcb", dependencies = TRUE)
```

Some functions in `iRfcb` require Python. You can download Python from the official website: [python.org/downloads](https://www.python.org/downloads/). For more details, please visit the project's [webpage](https://europeanifcbgroup.github.io/iRfcb/).

## Documentation and Tutorials

### Tutorial

- [iRfcb Tutorial](https://europeanifcbgroup.github.io/iRfcb/articles/tutorial/tutorial.html)

### Reference

- [Function Reference](https://europeanifcbgroup.github.io/iRfcb/reference/index.html)

## Repository

For more details and the latest updates, visit the [GitHub repository](https://github.com/EuropeanIFCBGroup/iRfcb).

## License

This package is licensed under the MIT License.
