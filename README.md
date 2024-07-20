# I 'R' FlowCytobot: Tools for analyzing and processing data from the Imaging FlowCytobot (IFCB)

[![R-CMD-check](https://github.com/anderstorstensson/iRfcb/actions/workflows/r-cmd-check.yml/badge.svg?event=push)](https://github.com/anderstorstensson/iRfcb/actions/workflows/r-cmd-check.yml)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.12533225.svg)](https://doi.org/10.5281/zenodo.12533225)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

## Overview

The `iRfcb` R package provides tools for working with Imaging FlowCytobot (IFCB) data, including quality control, particle size distribution analysis, and handling of annotated image data. This package facilitates the processing, analysis, and preparation of IFCB images and data for publication. It is especially useful for researchers using, or partly using, the MATLAB [ifcb-analysis](https://github.com/hsosik/ifcb-analysis) package (Sosik and Olson 2007).

## Installation

You can install the package from GitHub using the `devtools` package:

```r
# install.packages("devtools")
devtools::install_github("EuropeanIFCBGroup/iRfcb", dependencies = TRUE)
```

Some functions in `iRfcb` require Python. You can download Python from the official website: [python.org/downloads](https://www.python.org/downloads/).

## Getting Started

Load the `iRfcb` library:

```r
library(iRfcb)
```

## Documentation and Tutorials

For detailed usage instructions, including a tutorial, please refer to the [package documentation](https://europeanifcbgroup.github.io/iRfcb/) and the vignette available in the `vignettes` directory of the package. 

### Key Features

- **Quality Control:** Tools for analyzing particle size distribution and ensuring data quality.
- **Geospatial Analysis:** Functions to determine if the IFCB is near land or within specific marine basins.
- **Annotation Management:** Functions to count, summarize, and correct annotated image data.
- **Image Extraction:** Tools to extract and prepare images for publication.

## Repository

For more details and the latest updates, visit the [GitHub repository](https://github.com/anderstorstensson/iRfcb).

## License

This package is licensed under the MIT License.

## References

- Hayashi, K., Walton, J., Lie, A., Smith, J., and Kudela, M. Using particle size distribution (PSD) to automate imaging flow cytobot (IFCB) data quality in coastal California, USA. In prep.
- Menden-Deuer, S., & Lessard, E. J. (2000). Carbon to volume relationships for dinoflagellates, diatoms, and other protist plankton. Limnology and Oceanography, 45(3), 569-579. doi: 10.4319/lo.2000.45.3.0569.
- Sosik, H. M., & Olson, R. J. (2007). Automated taxonomic classification of phytoplankton sampled with imaging-in-flow cytometry. Limnology and Oceanography: Methods, 5, 204-216.
