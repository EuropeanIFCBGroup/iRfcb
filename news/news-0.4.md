# Version 0.4

## iRfcb 0.4.0

### New features

- Reorganized vignettes into multiple tutorials.
- Added `verbose` argument to functions:
  - [`ifcb_download_test_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_test_data.md)
  - [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  - [`ifcb_is_diatom()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_is_diatom.md)
  - [`ifcb_read_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_features.md)
  - [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
- Promoted WoRMS helper (`iRfcb:::retrieve_worms_records()`) to
  top-level function:
  [`ifcb_match_taxa_names()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_match_taxa_names.md).

## iRfcb 0.4.1

### Minor improvements and fixes

- Removed `imager` (replaced by `png`) in
  [`ifcb_extract_pngs()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_pngs.md)
  and `base64enc` dependencies.
- Added `gamma` argument to
  [`ifcb_extract_pngs()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_pngs.md).
- Updated vignettes.

## iRfcb 0.4.2

### Minor changes

- Updated documentation to pass CRAN checks.

## iRfcb 0.4.3

### Minor improvements and fixes

- [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
  now handles custom class lists.
- Updated documentation and vignettes.
- Improved speed of tests and vignette rendering.
- Removed unnecessary suggested packages: `fs` and `shinytest`.
