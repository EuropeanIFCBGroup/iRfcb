# iRfcb 0.6.0

## New features

* New functions for interacting with the IFCB Dashboard API: `ifcb_download_dashboard_metadata()` and `ifcb_list_dashboard_bins()`.
* Added `diatom_include` parameter to `ifcb_extract_biovolumes()` and `ifcb_summarize_biovolumes()` for manually forcing specific taxa to be treated as diatoms (overrides WoRMS classification) (#65).
* Added `bins` parameter to `ifcb_psd()` for selecting which bins to process.
* Added `fea_v` parameter to `ifcb_psd()` for selecting feature-file version.
* Added `use_plot_subfolders` parameter to `ifcb_psd()` to optionally save plots in subdirectories of `plot_folder` based on flag status.
* Added `flags` parameter to `ifcb_psd_plot()` to optionally add the quality flag annotation to the plot.

## Minor improvements and fixes

* `ifcb_extract_biovolumes()` now support both filename formats `_fea_v*.csv` and `_features_v*.csv`, increasing compatibility with legacy and new output formats (#61).
* `ifcb_read_features()`, `ifcb_summarize_png_metadata()`, `ifcb_summarize_biovolumes()`, and `ifcb_extract_biovolumes()` now include an optional parameter to select specific feature file versions (e.g., `_v2`, `_v4`), allowing finer control over which feature data are read and processed.
* The `$data`, `$fits` and `$flags` data frames returned by `ifcb_psd()` now use full bin names (`<sample>_<ifcb>`) as sample names, improving uniqueness and consistency with downstream workflows.
* The `$data` and `$fits` data frames returned by `ifcb_psd()` now preserves the original column names, including names starting with numbers or containing special characters.
* Problematic character µ returned from `ifcb_psd()` has been replaced by u in `$data` headers.
* Updated `$flags` headers in `ifcb_psd()` to use `sample` instead of `file`, ensuring consistent naming across all outputs.
* Reduced the size and resolution of saved plots in `ifcb_psd()` when `plot_folder` is specified, improving processing speed.

# iRfcb 0.5.2

## Minor improvements and fixes

* `ifcb_download_test_data()` gains checksum validation, `keep_zip` option, and improved retry logic.
* `ifcb_extract_biovolumes()` and `ifcb_summarize_biovolumes()` gain a `drop_zero_volume` option to exclude artifacts with zero biovolume
* `ifcb_read_features()` and `ifcb_extract_biovolumes()` now handles single `feature_files` correctly.
* Tests are now skipped if required resources are unavailable, improving stability in environments with limited access to external dependencies.

# iRfcb 0.5.1

## Minor improvements and fixes
* Skipping certain internet-required tests on CRAN servers.
* Corrected help pages for `ifcb_download_dashboard_data()` and `ifcb_download_whoi_plankton()`.

# iRfcb 0.5.0

## New features

* Added `NEWS.md` to track package changes.
* New functions:
  * `ifcb_download_dashboard_data()` for fetching data from the WHOI IFCB Dashboard.
  * `ifcb_download_whoi_plankton()` for downloading WHOI-Plankton PNG datasets.
  * `ifcb_prepare_whoi_plankton()` to process WHOI data for integration.
* New vignette: `vignette("whoi-plankton-data-integration")`.
* Python virtual environments can now be automatically activated by setting the
  `USE_IRFCB_PYTHON` environment variable when loading the package.
* Added scale bar support (#42) to:
  * `ifcb_extract_pngs()`
  * `ifcb_extract_classified_images()`
  * `ifcb_extract_annotated_images()`
* Added `gamma` argument to `ifcb_extract_annotated_images ()` and `ifcb_extract_classified_images()` for gamma correction.
* `ifcb_is_near_land()`:
  * Now returns a plot if `plot = TRUE`.
  * Added option to download EEA coastline data using the new argument `source`.
  * Deprecated the argument `utm_zone`, which is now determined automatically from
    longitude.

## Minor improvements and fixes

* `ifcb_read_hdr_data()` now correctly handles files from IFCB Acquire 1.x.x.x
  (#41).
* `ifcb_convert_filenames()` is more efficient and now correctly parses
  filenames like `"IFCB1_2010_309_192918"` (#40).
* The default location of the venv path in `ifcb_py_install()` has changed to
  "~/.virtualenvs/iRfcb".
* Added support for old `.adc` file format (IFCB1-6) by argument `old_adc` in:
  * `ifcb_extract_pngs()`
  * `ifcb_extract_classified_images()`
  * `ifcb_extract_annotated_images()`
* `ifcb_read_mat()` now returns consistent data structures aligned with
  `R.matlab::readMat()` (#50).

## Deprecations

* `ifcb_summarize_png_data()` is now defunct (previously deprecated in
  version 0.3.11).
* Deprecated arguments:
  * `adc_folder` in `ifcb_annotate_batch()` (replaced by `adc_files`).
  * `unclassified_id` in `ifcb_create_empty_manual_file()` (replaced by
    `classlist`).
  * `utm_zone` in `ifcb_is_near_land()` (now determined automatically from
    longitude).
* `ifcb_create_empty_manual_file()` now accepts a complete class list via
  `classlist`, replacing the older `unclassified_id`.

# iRfcb 0.4.3

## Minor improvements and fixes

* `ifcb_summarize_biovolumes()` now handles custom class lists.
* Updated documentation and vignettes.
* Improved speed of tests and vignette rendering.
* Removed unnecessary suggested packages: `fs` and `shinytest`.

# iRfcb 0.4.2

## Minor changes

* Updated documentation to pass CRAN checks.

# iRfcb 0.4.1

## Minor improvements and fixes

* Removed `imager` (replaced by `png`) in `ifcb_extract_pngs()` and `base64enc` dependencies.
* Added `gamma` argument to `ifcb_extract_pngs()`.
* Updated vignettes.

# iRfcb 0.4.0

## New features

* Reorganized vignettes into multiple tutorials.
* Added `verbose` argument to functions: 
  * `ifcb_download_test_data()`
  * `ifcb_extract_biovolumes()`
  * `ifcb_is_diatom()`
  * `ifcb_read_features() `
  * `ifcb_summarize_biovolumes()`
* Promoted WoRMS helper (`iRfcb:::retrieve_worms_records()`) to top-level function: `ifcb_match_taxa_names()`.

# iRfcb 0.3.15

## Minor improvements and fixes

* Fixed issue in `ifcb_get_ferrybox_data()` where multiple close ferrybox timestamps caused duplicate rows. Now returns only the nearest match.

# iRfcb 0.3.14

## Minor improvements and fixes

* Updated SHARK example in `ifcb_get_shark_example()` and `ifcb_get_shark_colnames()` for testing and documentation.

# iRfcb 0.3.13

## New features

* Added `ifcb_merge_manual()` to merge manual `.mat` datasets.
* Added `ifcb_adjust_classes()` to adjust classes in manual data.
* Added `ifcb_create_class2use()` to generate a class2use file.

# iRfcb 0.3.12

## New features

* Added `ifcb_create_empty_manual_file()` to create new manual `.mat` files.
* Added `ifcb_annotate_batch()` to annotate multiple `.mat` files in a batch based on `.png` images.

## Minor improvements and fixes

* Compressed `.mat` files to save space using `do_compression` argument in:
  * `ifcb_correct_annotation()`
  * `ifcb_replace_mat_values()`

# iRfcb 0.3.11

## New features

* Added `ifcb_summarize_png_metadata()` to summarize EcoTaxa metadata.
* Added `ifcb_get_ecotaxa_example()` to extract EcoTaxa headers and example data.

## Minor improvements and fixes

* Large ZIP files can now be split using helper `iRfcb:::split_large_zip()` in `ifcb_zip_pngs()`.

## Deprecations

* Deprecated `ifcb_summarize_png_data()` (replaced by
  `ifcb_summarize_png_counts()`).

# iRfcb 0.3.10

## Minor improvements and fixes

* Updated documentation and examples.

## Deprecations

* Removed deprecated function `ifcb_get_svea_position()`.
* Removed helper `iRfcb:::handle_missing_positions()`.
* Deprecated arguments `manual_folder`, `feature_folder`, and `class_folder`
  in several functions (`ifcb_count_mat_annotations()`,
  `ifcb_extract_biovolumes()`, `ifcb_read_features()`,
  `ifcb_summarize_biovolumes()`.

# iRfcb 0.3.9

## Minor improvements and fixes

* Fixed edge case where `nrow(taxa_list) == 0` in `ifcb_count_mat_annotations()`.
* Added `mat_recursive` option to `ifcb_count_mat_annotations()`.
* Added `manual_recursive` option to `ifcb_extract_annotated_images()` and `ifcb_zip_matlab()`.
* Added `roi_recursive` option to `ifcb_extract_annotated_images()`.
* Added `data_recursive` option to `ifcb_zip_matlab()`.
* Added `feature_recursive` option to `ifcb_zip_matlab()`.

# iRfcb 0.3.8

## Minor improvements and fixes

* Added `marine_only` to `ifcb_is_diatom()`, `iRfcb:::retrieve_worms_records()`, `ifcb_summarize_biovolumes()` and `ifcb_extract_biovolumes()`.
* Added `feature_recursive` to `ifcb_extract_biovolumes()` and `ifcb_summarize_biovolumes()`.
* Added `mat_recursive` to `ifcb_extract_biovolumes()` and `ifcb_summarize_biovolumes()`.
* Added `hdr_recursive` to `ifcb_summarize_biovolumes()`.
* Extracted helper function from `ifcb_is_diatom()`.

# iRfcb 0.3.7

## New features

* Added classifier name to output from MATLAB extraction in `ifcb_summarize_biovolumes()`.

# iRfcb 0.3.6

## Minor improvements and fixes

* Removed Öresund from included Baltic Sea shape file used in `ifcb_is_in_basin()`.
* Updated SHARK column names for compatibility in `ifcb_get_shark_example()` and `ifcb_get_shark_colnames()`.

# iRfcb 0.3.5

## Minor improvements and fixes

* Improved error handling in WoRMS API calls with multiple attempts in `iRfcb:::retrieve_worms_records()`.
* Updated package title.

## Deprecations

* Deprecated `ifcb_get_svea_position()` (replaced by `ifcb_get_ferrybox_data()`).

# iRfcb 0.3.4

## Minor improvements and fixes

* Added option to summarize biovolumes from manual files in `ifcb_summarize_biovolumes()`.
* Added `sleep_time` parameter for `ifcb_download_test_data()`.

# iRfcb 0.3.3

## Minor improvements and fixes

* Fixed manual `.mat` count edge case.
* Switched to `curl` for downloads.
* Parameterized PSD micron factor in `ifcb_psd()` with argument `micron_factor`.
* General clean-up of minor improvements and fixes.

# iRfcb 0.3.2

## Minor improvements and fixes

* Replaced test data with a smaller dataset.
* Improved unit test coverage.

# iRfcb 0.3.1

## Minor improvements and fixes

* Corrected documentation errors.

# iRfcb 0.3.0

## New features

* Introduced unit testing with `testthat` for improve stability.
* Improved consistency and functionality across multiple functions.

# iRfcb 0.2.6

## Minor improvements and fixes

* Minor update of documentation for clarity and consistency.

# iRfcb 0.2.5

## Minor improvements and fixes

* Improved pkgdown webpage.
* Refined tutorial content.
* General code cleanup and internal documentation improvements.

# iRfcb 0.2.4

## Minor improvements and fixes

* Moved example documentation to vignettes.
* Added `verbose` argument to several functions to provide detailed progress messages during execution.

# iRfcb 0.2.3

## Minor improvements and fixes

* `ifcb_replace_mat_values()` now only handles `.mat` files in the
  `manual_folder`.
* Made more examples runnable by including relevant example data in the package.

# iRfcb 0.2.2

## Minor improvements and fixes

* `ifcb_is_near_land()` now returns `NA` if coordinates passed to the function
  contain `NA` values.

# iRfcb 0.2.1

## New features

* Added `ifcb_get_trophic_type()` to assign trophic strategy to taxa.

## Minor improvements and fixes

* `ifcb_get_shark_colnames()`:
  * Added SHARK columns: `WADEP`, `PDMET`, `METFP`, `IFCBNO`, `TRPHY`, `ABUND`,
    and `BIOVOL`.
  * Removed deprecated columns: `SAMPLE_TIME`, `ABUND_UNITS_PER_LITER`,
    `BIOVOL_PER_SAMPLE`, `BIOVOL_PER_LITER`, `C_CONC_PER_LITER`, and
    `SEA_BASIN`.

# iRfcb 0.2.0

## New features

* New functions:
  * `extract_aphia_id()`: Extract AphiaID from WoRMS record.
  * `extract_class()`: Extract taxonomic class from WoRMS record.
  * `handle_missing_positions()`: Handle missing positions by rounding
    timestamps.
  * `ifcb_extract_biovolumes()`: Compute biovolumes and carbon from IFCB data.
  * `ifcb_get_shark_colnames()`: Retrieve column names for SHARK submission.
  * `ifcb_get_svea_position()`: Extract GPS coordinates from ferrybox data.
  * `ifcb_is_diatom()`: Identify diatoms in a taxa list.
  * `ifcb_is_in_basin()`: Check whether points fall inside a sea basin.
  * `ifcb_psd_plot()`: Create particle size distribution plots from IFCB data.
  * `ifcb_read_features()`: Read IFCB feature files from a specified folder.
  * `ifcb_summarize_biovolumes()`: Summarize biovolumes and carbon content.
  * `ifcb_summarize_class_counts()`: Count TreeBagger classifier outputs.
  * `ifcb_which_basin()`: Return name of sea basin a point belongs to.
  * `summarize_TBclass()`: Summarize TreeBagger classifier results.
  * `vol2C_lgdiatom()`: Convert biovolume to carbon for large diatoms.
  * `vol2C_nondiatom()`: Convert biovolume to carbon for non-diatom protists.

## Minor improvements and fixes

* Fixed issue in `ifcb_read_hdr_data()` where `gps_only` filtering could fail.
* Extended tutorial to include examples using newly added functions.

# iRfcb 0.1.2

## Minor improvements and fixes

* Fixed edge case in `ifcb_volume_analyzed()` when inhibition `time == 0`
  (#2).

# iRfcb 0.1.1

## Minor improvements and fixes

* Fixed warning in `ifcb_is_near_land()` by applying
  `sf::st_wrap_dateline()` only when the CRS is geographic.
* Updated function documentation for consistency.

# iRfcb 0.1.0

Initial development release of `iRfcb`.

## Features

* Core functionality for reading and analyzing IFCB data, including:
  * `ifcb_convert_filenames()`
  * `ifcb_correct_annotation()`
  * `ifcb_count_mat_annotations()`
  * `ifcb_create_manifest()`
  * `ifcb_download_test_data()`
  * `ifcb_extract_annotated_images()`
  * `ifcb_extract_classified_images()`
  * `ifcb_extract_pngs()`
  * `ifcb_get_mat_names()`
  * `ifcb_get_mat_variables()`
  * `ifcb_get_runtime()`
  * `ifcb_is_near_land()`
  * `ifcb_psd()`
  * `ifcb_py_install()`
  * `ifcb_read_hdr_data()`
  * `ifcb_read_summary()`
  * `ifcb_replace_mat_values()`
  * `ifcb_run_image_gallery()`
  * `ifcb_summarize_png_data()`
  * `ifcb_volume_analyzed_from_adc()`
  * `ifcb_volume_analyzed()`
  * `ifcb_zip_matlab()`
  * `ifcb_zip_pngs()`
