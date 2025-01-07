# I 'R' FlowCytobot (iRfcb): Tools for Analyzing and Processing Data from the IFCB <a href="https://europeanifcbgroup.github.io/iRfcb/"><img src="man/figures/logo.png" align="right" height="139" alt="iRfcb website" /></a>

[![R-CMD-check](https://github.com/EuropeanIFCBGroup/iRfcb/actions/workflows/r-cmd-check.yml/badge.svg?event=push)](https://github.com/EuropeanIFCBGroup/iRfcb/actions/workflows/r-cmd-check.yml)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.12533225.svg)](https://doi.org/10.5281/zenodo.12533225)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![Codecov test coverage](https://codecov.io/gh/EuropeanIFCBGroup/iRfcb/branch/main/graph/badge.svg)](https://app.codecov.io/gh/EuropeanIFCBGroup/iRfcb?branch=main)
[![CodeFactor](https://www.codefactor.io/repository/github/europeanifcbgroup/irfcb/badge)](https://www.codefactor.io/repository/github/europeanifcbgroup/irfcb)

## Overview

The `iRfcb` R package offers a suite of tools for managing and performing quality control on plankton data generated by the [Imaging FlowCytobot (IFCB)](https://mclanelabs.com/imaging-flowcytobot/). It streamlines the processing and analysis of IFCB data, facilitating the preparation of IFCB data and images for publication (e.g. in [GBIF](https://www.gbif.org/ipt), [OBIS](https://obis.org/), [EMODNet Biology](https://emodnet.ec.europa.eu/en/biology), [SHARK](https://shark.smhi.se/) or [EcoTaxa](https://ecotaxa.obs-vlfr.fr)). It is especially useful for researchers using, or partly using, the MATLAB [ifcb-analysis](https://github.com/hsosik/ifcb-analysis) package.

### Key Features

- **Data Management**: Comprehensive functions for reading IFCB files, counting and summarizing annotated and classified image data, correcting and merging manually annotated datasets.
- **Quality Control**: Tools for geospatial quality control of IFCB data and analysis of [Particle Size Distribution](https://github.com/kudelalab/PSD).
- **Image Extraction**: Tools to extract and prepare images for publication.
- **Taxonomical Data**: Tools for handling and analyzing taxonomic data and calculating biomass concentration from image data.

## Installation

You can install the package from GitHub using the `devtools` package:

```r
# install.packages("devtools")
devtools::install_github("EuropeanIFCBGroup/iRfcb", dependencies = TRUE)
```

Some functions in `iRfcb` require Python. You can download Python from the official website: [python.org/downloads](https://www.python.org/downloads/). For more details, please visit the project's [webpage](https://europeanifcbgroup.github.io/iRfcb/).

## Documentation and Tutorials

### Reference

For a detailed overview of all available `iRfcb` functions, please visit the reference section:

- [Function Reference](https://europeanifcbgroup.github.io/iRfcb/reference/index.html)

### Tutorials

Explore the key features and capabilities of `iRfcb` through the tutorials:

- [iRfcb Introduction](https://europeanifcbgroup.github.io/iRfcb/articles/a-general-tutorial.html)
- [Quality Control of IFCB Data](https://europeanifcbgroup.github.io/iRfcb/articles/qc-tutorial.html)
- [Handling MATLAB Results](https://europeanifcbgroup.github.io/iRfcb/articles/matlab-tutorial.html)
- [Creating a DwC-A from IFCB Data](https://europeanifcbgroup.github.io/iRfcb/articles/dwca-tutorial.html)
- [Sharing Annotated IFCB Images](https://europeanifcbgroup.github.io/iRfcb/articles/image-export-tutorial.html)
- [Prepare IFCB Images for EcoTaxa](https://europeanifcbgroup.github.io/iRfcb/articles/ecotaxa-tutorial.html)

### Example Useage

`iRfcb` is designed for integration into IFCB data processing pipelines. For an example, see its implementation in the following project:

- [Example Data Pipelines](https://github.com/nodc-sweden/ifcb-data-pipeline)

## Repository

For more details and the latest updates, visit the [GitHub repository](https://github.com/EuropeanIFCBGroup/iRfcb).

## License

This package is licensed under the MIT License.
