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
  WoRMS classification)
  ([\#65](https://github.com/EuropeanIFCBGroup/iRfcb/issues/65)).
- Added `bins` parameter to
  [`ifcb_psd()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_psd.md)
  for selecting which bins to process.
- Added `fea_v` parameter to
  [`ifcb_psd()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_psd.md)
  for selecting feature-file version.
- Added `use_plot_subfolders` parameter to
  [`ifcb_psd()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_psd.md)
  to optionally save plots in subdirectories of `plot_folder` based on
  flag status.
- Added `flags` parameter to
  [`ifcb_psd_plot()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_psd_plot.md)
  to optionally add the quality flag annotation to the plot.

### Minor improvements and fixes

- [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  now support both filename formats `_fea_v*.csv` and
  `_features_v*.csv`, increasing compatibility with legacy and new
  output formats
  ([\#61](https://github.com/EuropeanIFCBGroup/iRfcb/issues/61)).
- [`ifcb_read_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_features.md),
  [`ifcb_summarize_png_metadata()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_png_metadata.md),
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md),
  and
  [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  now include an optional parameter to select specific feature file
  versions (e.g., `_v2`, `_v4`), allowing finer control over which
  feature data are read and processed.
- The `$data`, `$fits` and `$flags` data frames returned by
  [`ifcb_psd()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_psd.md)
  now use full bin names (`<sample>_<ifcb>`) as sample names, improving
  uniqueness and consistency with downstream workflows.
- The `$data` and `$fits` data frames returned by
  [`ifcb_psd()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_psd.md)
  now preserves the original column names, including names starting with
  numbers or containing special characters.
- Problematic character µ returned from
  [`ifcb_psd()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_psd.md)
  has been replaced by u in `$data` headers.
- Updated `$flags` headers in
  [`ifcb_psd()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_psd.md)
  to use `sample` instead of `file`, ensuring consistent naming across
  all outputs.
- Reduced the size and resolution of saved plots in
  [`ifcb_psd()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_psd.md)
  when `plot_folder` is specified, improving processing speed.
