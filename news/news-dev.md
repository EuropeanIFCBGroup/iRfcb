# Version dev

## iRfcb (development version)

### New features

- New functions for interacting with the IFCB Dashboard API:
  [`ifcb_download_dashboard_metadata()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_dashboard_metadata.md)
  and
  [`ifcb_list_dashboard_bins()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_list_dashboard_bins.md).
- Added `diatom_include` parameter to
  [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  and
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
  for manually forcing specific taxa to be treated as diatoms (overrides
  WoRMS classification).

### Minor improvements and fixes

- [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  now support both filename formats `_fea_v*.csv` and
  `_features_v*.csv`, increasing compatibility with legacy and new
  output formats.
  ([\#61](https://github.com/EuropeanIFCBGroup/iRfcb/issues/61))
- [`ifcb_read_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_features.md),
  [`ifcb_summarize_png_metadata()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_png_metadata.md),
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md),
  and
  [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  now include an optional parameter to select specific feature file
  versions (e.g., `_v2`, `_v4`), allowing finer control over which
  feature data are read and processed.
