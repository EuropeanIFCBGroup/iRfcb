# Version 0.2

## iRfcb 0.2.0

### New features

- New functions:
  - `extract_aphia_id()`: Extract AphiaID from WoRMS record.
  - `extract_class()`: Extract taxonomic class from WoRMS record.
  - `handle_missing_positions()`: Handle missing positions by rounding
    timestamps.
  - [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md):
    Compute biovolumes and carbon from IFCB data.
  - [`ifcb_get_shark_colnames()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_shark_colnames.md):
    Retrieve column names for SHARK submission.
  - `ifcb_get_svea_position()`: Extract GPS coordinates from ferrybox
    data.
  - [`ifcb_is_diatom()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_is_diatom.md):
    Identify diatoms in a taxa list.
  - [`ifcb_is_in_basin()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_is_in_basin.md):
    Check whether points fall inside a sea basin.
  - [`ifcb_psd_plot()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_psd_plot.md):
    Create particle size distribution plots from IFCB data.
  - [`ifcb_read_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_features.md):
    Read IFCB feature files from a specified folder.
  - [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md):
    Summarize biovolumes and carbon content.
  - [`ifcb_summarize_class_counts()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_class_counts.md):
    Count TreeBagger classifier outputs.
  - [`ifcb_which_basin()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_which_basin.md):
    Return name of sea basin a point belongs to.
  - [`summarize_TBclass()`](https://europeanifcbgroup.github.io/iRfcb/reference/summarize_TBclass.md):
    Summarize TreeBagger classifier results.
  - [`vol2C_lgdiatom()`](https://europeanifcbgroup.github.io/iRfcb/reference/vol2C_lgdiatom.md):
    Convert biovolume to carbon for large diatoms.
  - [`vol2C_nondiatom()`](https://europeanifcbgroup.github.io/iRfcb/reference/vol2C_nondiatom.md):
    Convert biovolume to carbon for non-diatom protists.

### Minor improvements and fixes

- Fixed issue in
  [`ifcb_read_hdr_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_hdr_data.md)
  where `gps_only` filtering could fail.
- Extended tutorial to include examples using newly added functions.

## iRfcb 0.2.1

### New features

- Added
  [`ifcb_get_trophic_type()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_trophic_type.md)
  to assign trophic strategy to taxa.

### Minor improvements and fixes

- [`ifcb_get_shark_colnames()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_shark_colnames.md):
  - Added SHARK columns: `WADEP`, `PDMET`, `METFP`, `IFCBNO`, `TRPHY`,
    `ABUND`, and `BIOVOL`.
  - Removed deprecated columns: `SAMPLE_TIME`, `ABUND_UNITS_PER_LITER`,
    `BIOVOL_PER_SAMPLE`, `BIOVOL_PER_LITER`, `C_CONC_PER_LITER`, and
    `SEA_BASIN`.

## iRfcb 0.2.2

### Minor improvements and fixes

- [`ifcb_is_near_land()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_is_near_land.md)
  now returns `NA` if coordinates passed to the function contain `NA`
  values.

## iRfcb 0.2.3

### Minor improvements and fixes

- [`ifcb_replace_mat_values()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_replace_mat_values.md)
  now only handles `.mat` files in the `manual_folder`.
- Made more examples runnable by including relevant example data in the
  package.

## iRfcb 0.2.4

### Minor improvements and fixes

- Moved example documentation to vignettes.
- Added `verbose` argument to several functions to provide detailed
  progress messages during execution.

## iRfcb 0.2.5

### Minor improvements and fixes

- Improved pkgdown webpage.
- Refined tutorial content.
- General code cleanup and internal documentation improvements.

## iRfcb 0.2.6

### Minor improvements and fixes

- Minor update of documentation for clarity and consistency.
