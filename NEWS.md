# iRfcb 0.10.0

## New features

* Added support for the optional per-ROI `cell_count` data produced by the diatom chain counter (Groves et al. 2026, [doi:10.1093/plankt/fbaf064](https://doi.org/10.1093/plankt/fbaf064)) via the [`ifcb-pytorch-classify`](https://github.com/nodc-sweden/ifcb-pytorch-classify) inference pipeline, and stored in `.mat`/`.h5`/`.csv` classification files. This enables reporting cell abundance (accounting for chains) in addition to ROI counts.
  * New `ifcb_summarize_cell_counts()` summarizes cell abundance and user-selectable chain-length statistics (`mean`, `median`, `max`, `sd`, `n_chains`) per sample and class, with optional per-liter abundance via an `hdr_folder`.
  * `ifcb_summarize_biovolumes()` and `ifcb_extract_biovolumes()` gain a `use_cell_counts` argument. When `TRUE`, `ifcb_summarize_biovolumes()` adds `cell_counts` (and `cell_counts_per_liter` when an `hdr_folder` is supplied) to the output.
  * A `single_cell_values` argument (default `c(-1, 0)`) lets the user define which `cell_count` values are treated as a single cell. By default, ROIs that were not chain-counted (`-1`) and ROIs where no cells were detected (`0`) each count as one cell; any other value is used verbatim.
  * `cell_counts` is `NA` for a sample whose classification file carries no `cell_count` data at all, since the cell total is unknown there. It is deliberately not reported as `0`, which would be indistinguishable from a taxon that was genuinely absent, and `counts` still reports the ROIs. A warning names how many of the supplied files were affected.
  * The bundled SHARK column template (`ifcb_get_shark_colnames()` and `ifcb_get_shark_example()`) gains an `IMAGE_COUNT` column (the number of ROIs, i.e. images), placed after `COUNT`. When the `COUNT` and `ABUND` columns report cells, dividing `COUNT` by `IMAGE_COUNT` gives the average number of cells per image. That is not the same as the `mean_chain_length` reported by `ifcb_summarize_cell_counts()`, because the two divide by different numbers of images: `COUNT` counts every image, treating one the chain counter did not measure as a single cell, whereas `mean_chain_length` averages only over the images it did measure. Take a taxon with four images, of which the counter measured three at 5, 8 and 1 cells and did not measure the fourth. Dividing `COUNT` by `IMAGE_COUNT` gives 15 divided by 4, or 3.75, while `mean_chain_length` is 14 divided by 3, or 4.67. For a taxon the chain counter was never configured for, nothing is measured at all: dividing `COUNT` by `IMAGE_COUNT` then gives exactly 1, while `mean_chain_length` is `NA`.
* `ifcb_extract_biovolumes()` and `ifcb_summarize_biovolumes()` gain control over how the Menden-Deuer and Lessard (2000) carbon-to-volume relationships are applied, through the new `diatom_equation` and `carbon_conversion` arguments. Both default to the previous behavior, so carbon values are unchanged unless one is set.
  * `diatom_equation` selects which diatom relationship to use. `"large"` (the default) uses the large-diatom (> 3000 micron^3) equation, matching the `ifcb-analysis` convention; `"all"` uses the all-sizes equation, which assigns more carbon to small cells; and `"auto"` selects between them per volume, keeping each within its calibrated size range. New exported helpers `vol2C_diatom()` and `vol2C_diatom_auto()` implement the all-sizes relationship (log a = -0.541, b = 0.811) and the volume-based selection. Non-diatom protists always use `vol2C_nondiatom()`. Note that the two diatom relationships are discontinuous at the 3000 micron^3 boundary, predicting about 190 and 135 pgC respectively, so `"auto"` makes predicted carbon fall as a cell grows across it; that is why `"large"` remains the default. `"auto"` needs no chain-count data and is available to every user, addressing the case where the default equation is applied to ROIs well below the size range it was fitted for.
  * `carbon_conversion` selects what volume the chosen equation is applied to. The relationships are fitted per cell (`log pgC cell^-1 = log a + b * log V`), but an IFCB biovolume describes a whole region of interest, which for a chain-forming diatom is the whole chain. Since every relationship has `b < 1`, applying one to an aggregated chain volume returns less carbon than applying it per cell and summing; the two differ by a factor of `n^(1-b)`, about 1.28 for an 8-cell chain and 1.43 for 20 cells under the large-diatom equation. `"roi"` (the default) applies the equation once to the ROI biovolume; `"cell"` divides by the resolved cell count, converts, and multiplies back, and requires `use_cell_counts = TRUE`. `carbon_pg` and `carbon_ug` remain per-ROI and per-class totals in both cases, never carbon per cell. Only ROIs with `cell_count >= 2` are affected: single cells, ROIs that were never chain-counted, and ROIs from files carrying no `cell_count` data are all converted as one cell.
  * Biovolume itself is unaffected by either argument, since summing cell volumes is linear. It is still measured per region of interest, so chains of small cells register a large ROI biovolume.
* Added `ifcb_qc_sample()`, which validates the integrity and self-consistency of raw IFCB samples (the `.hdr`/`.adc`/`.roi` triplet) and returns a tidy tibble of QC metrics and flags, one row per sample. Checks cover triplet completeness, ROI count consistency (imaged ROIs in the ADC versus the header `roiCount`), ROI data completeness (detecting truncated/aborted `.roi` files by comparing the file size to the last image's end offset), header/ADC run time consistency, and flow/volume sanity via `ifcb_volume_analyzed()` (the volume ceiling is derived per sample from the header `SyringeSampleVolume`, reported as `syringe_ml`, rather than a fixed value, falling back to the 5 mL IFCB standard when the header reports no positive value; a constant ceiling can be forced with `max_ml`). Bead/calibration runs (`is_bead_run`) and empty samples (`is_empty`) are flagged separately as advisory, as are, via the optional `max_roi_mb`, `max_humidity` and `max_temperature` arguments, oversized `.roi` files (`roi_oversized`) and high recorded humidity or temperature (`humidity_high` / `temperature_high`). Advisory flags describe valid samples that a user may nonetheless wish to exclude and so do not affect the overall `qc_pass` column. A check that cannot be evaluated for a given sample is reported as `NA` and treated as not applicable, so it does not fail `qc_pass`: legacy headers omitting `roiCount` cannot be checked for ROI count consistency, and a sample that never triggered has no analyzed volume to check (`is_empty` reports that condition instead). Malformed, non-numeric ROI dimensions in an `.adc` are treated as not imaged, so one damaged file cannot abort a whole survey. The function accepts a directory, sample names with a `data_folder`, or explicit file paths, and builds entirely on existing native-R readers (no Python required).

## Minor improvements and fixes

* `ifcb_extract_biovolumes()` and `ifcb_summarize_biovolumes()` now abort when one sample resolves to more than one classification file (e.g. a folder holding both a `{sample}_class_v1.mat` and a `{sample}_class.h5`), naming the affected samples. Previously both files were read and joined, silently duplicating that sample's ROIs and so doubling its `counts`, `biovolume_mm3` and `carbon_ug`. `ifcb_summarize_cell_counts()` applies the same check.
* The classification-file readers used by `ifcb_extract_biovolumes()`, `ifcb_summarize_biovolumes()`, and `ifcb_summarize_cell_counts()` are now robust to non-class `.csv` files in a class directory. Previously a directory that also contained an IFCB-Dashboard class_scores export (`{sample}_class.csv`, with a `pid` column plus one score column per class, and no `file_name`/`class_name` columns) could be picked up and either silently tolerated or fail later with a cryptic `Unknown or uninitialised column: 'class'` error followed by a WoRMS (400) Bad Request. When a folder is supplied, such files are now skipped with a warning naming the file and the missing columns, so a directory mixing dashboard score exports with ClassiPyR label files runs cleanly using only the valid label files. When a non-class `.csv` is passed explicitly, the reader aborts with a clear message identifying the file and the missing columns.
* `ifcb_is_diatom()` gains a `details` argument. When `TRUE`, it returns a data frame with the resolved WoRMS class (`worms_class`) for each taxon instead of a logical vector, making it possible to audit genus homonyms, i.e. diatom genera such as `Navicula` or `Actinocyclus` whose names are shared with animals and therefore resolve to a non-diatom class in WoRMS. Inspect the `worms_class` column to identify such cases and add the affected taxa to `diatom_include`.
* `ifcb_extract_biovolumes()` and `ifcb_summarize_biovolumes()` now report the diatom classification more usefully when `verbose = TRUE`: the (typically short) list of classes treated as diatoms is printed in full, classes that could not be found in WoRMS are listed separately, and the (typically long) list of non-diatom classes is summarized as a count with a pointer to `ifcb_is_diatom(details = TRUE)` for auditing homonyms. Previously the full non-diatom list was printed and truncated with an ellipsis, making it hard to tell whether a class expected to be a diatom had actually been recognized as one.
* Removed the Python dependency from all functions that create or edit MATLAB `ifcb-analysis` manual classification files. `ifcb_create_class2use()`, `ifcb_create_manual_file()` (and the deprecated `ifcb_create_empty_manual_file()`), `ifcb_adjust_classes()`, `ifcb_correct_annotation()`, `ifcb_replace_mat_values()`, and the `format = "mat"` output of `ifcb_save_classification()` now write `.mat` files with a native R implementation of the MATLAB Level 5 MAT-file format, producing output identical to the previous `scipy.io.savemat`-based approach (byte-for-byte identical when uncompressed, and identical in content when compressed). The wrapper functions `ifcb_annotate_batch()`, `ifcb_annotate_samples()`, `ifcb_merge_manual()`, and `ifcb_prepare_whoi_plankton()`, which delegate to the above, are therefore also Python-free. This removes the `scipy`/`numpy` requirement for creating and editing manual annotation files.
* Removed the `R.matlab` package as a dependency. The default (non-Python) path for *reading* `.mat` files now also uses the native R MAT-file reader instead of `R.matlab::readMat()`, affecting `ifcb_get_mat_names()`, `ifcb_get_mat_variable()`, `ifcb_read_summary()`, `ifcb_count_mat_annotations()`, `ifcb_extract_annotated_images()`, and the reading of `.mat` classification files. The native reader decodes MATLAB-generated UTF-16 character data correctly, so non-ASCII strings (e.g. accented class or path names) that `R.matlab::readMat()` could mangle are now preserved. It rejects input it cannot represent faithfully rather than decoding it as numeric data: MATLAB structs, objects, sparse arrays, complex and logical arrays, arrays with more than two dimensions, and multi-row character arrays each raise an error naming the variable and the unsupported feature. It also bounds-checks element lengths against the file, so a truncated `.mat` file is reported rather than read back zero-filled. Both matter because `ifcb_adjust_classes()` and `ifcb_correct_annotation()` write the variables they read back over the same file. `R.matlab` has been moved from `Imports` to `Suggests` (used only as an independent cross-check in the test suite).
* `ifcb_extract_features()` now supports both raw-data readers used by the WHOI [`ifcb-features`](https://github.com/WHOIGit/ifcb-features) package. Release v1.1.0 replaced its `pyifcb` dependency with the much lighter [`ifcbkit`](https://github.com/WHOIGit/ifcbkit), which exposes a different API; `iRfcb` previously required `pyifcb` and therefore failed against v1.1.0 and later. Since `ifcb_py_install(features = TRUE)` installs the latest release by default, this affected new installations. Raw data is now read through an adapter that uses whichever reader is available (`ifcbkit` preferred when both are), so `ifcb-features` v1.0.0 and v1.1.x both work, including with both readers installed in the same environment. A new `backend` argument (or the `IRFCB_IFCB_BACKEND` environment variable) forces a specific reader. The `ifcb_features` code is unchanged between these releases, so the choice of reader does not affect how a region of interest is measured, and for the D-style bins produced by current instruments the two readers agree on ROI numbering and pixel data. They differ in two respects, both confined to older or malformed data: `pyifcb` skips a ROI whose recorded width is zero while `ifcbkit` skips one whose width *or* height is zero, and `ifcbkit` stitches overlapping ROI pairs in I-style bins that `pyifcb` returns separately. Pin a reader with `backend` if results must be comparable to an earlier run on I-style data. Note that installing `ifcb-features` v1.1.0 or later no longer pulls in `h5py` (via `pyifcb`), removing the binary-wheel constraint that previously limited which Python versions could be used.
* Fixed `ifcb_extract_features()` writing non-numeric values into the `Eccentricity`, `MajorAxisLength` and `MinorAxisLength` columns of `<bin>_features_v4.csv`. `ifcb_features` derives these from `numpy.linalg.eig`, which returns complex eigenvalues (with a zero imaginary part) for real symmetric input from `numpy` 2.3 and later; they were written as strings such as `(0.797+0j)`, silently turning three numeric columns into text. The real part is now taken, so the columns are numeric again and the values are unchanged. Where the imaginary part is *not* zero - a degenerate, collinear blob can make `numpy.cov()` return a slightly negative eigenvalue, and the axis length is `4 * sqrt(eigenvalue)` - the blob is now measured as `0`. That matches upstream `ifcb-features`, which guards the same case by clipping the eigenvalue to zero before taking the square root ([WHOIGit/ifcb-features#20](https://github.com/WHOIGit/ifcb-features/pull/20), merged after the current v1.1.1 release), so a given blob measures the same whichever `ifcb-features` release is installed. It also agrees with `summedMinorAxisLength`, which `ifcb_features` itself already reports as `0` for such a blob on `numpy` >= 2.3, having cast the same complex value to its real part. Note for downstream size-spectrum and biovolume aggregation that these blobs - one pixel wide, and rare - therefore contribute a zero rather than a filterable missing value. Earlier runs remain reproducible by pinning the environment rather than by any `iRfcb` setting: with `ifcb-features` v1.0.0, or any environment with `numpy` < 2.3, `numpy.linalg.eig` returns real eigenvalues, the square root of a negative one is `NaN` (and, since `numpy.max()`/`numpy.min()` propagate it, all three columns become `NaN`), and `iRfcb` passes that through unchanged. This only affected environments with `numpy` >= 2.3, which became reachable when `ifcb-features` v1.1.0 dropped the `pyifcb` dependency whose pinned `scipy` had previously capped `numpy`. Feature values and blob masks are otherwise unchanged across old and new `numpy`/`scikit-image`/`scipy` versions.
* `ifcb_extract_features()` no longer emits a `FutureWarning` per region of interest from recent `scikit-image` releases, which had obscured the progress bar. Two filters are needed, because a warning is matched against the module it is attributed to rather than the one that started the call chain. One covers the deprecated functions `ifcb_features` calls itself; the other covers `scikit-image` calling its own deprecated functions internally (`binary_closing()` calls `binary_erosion()`), which is attributed to `skimage` and so escaped the first filter. `scikit-image` guards that inner call with a `warnings.catch_warnings()` block, but that swaps the global filter list and is not thread-safe, so under the thread pool used when Python is embedded on Windows and macOS the warning leaked out sporadically - once in a long run rather than once per region of interest. `ifcb_py_install(features = TRUE)` additionally constrains `scikit-image` to `< 0.28`, the release that removes the deprecated morphology functions `ifcb_features` calls; without the bound, a future `scikit-image` release would break `ifcb-features` v1.1.x installs, which (unlike v1.0.0, pinned via `pyifcb`) leave the version unconstrained.
* `ifcb_extract_features()` gains a `feature_tag` argument to control the feature file naming. The default (`"features"`) writes `<bin>_features_v4.csv` as before; `"fea"` writes `<bin>_fea_v4.csv`, the name served by the IFCB Dashboard (pyifcb's `FeaturesDirectory`).
* Fixed `ifcb_volume_analyzed_from_adc()` failing when given more than one ADC file, or a URL. The existence check was not vectorized, so a character vector of ADC files aborted with `the condition has length > 1` even though the body already looped over each file, and the check rejected URLs outright because `file.exists()` is always `FALSE` for one, despite the body handling remote files. Local paths are now validated individually (with all missing paths reported at once) and URLs are passed straight through.
* `ifcb_correct_annotation()` and `ifcb_replace_mat_values()` now validate their inputs and fail with actionable messages instead of an opaque error. Out-of-range ROI numbers and an out-of-range `column_index` report the value and the valid range (previously `subscript out of bounds`), and a missing input file or a `.mat` file without a `classlist` variable is now named explicitly.
* `ifcb_extract_features()` no longer aborts an entire sequential run when a bin cannot be read. With `pyifcb`, images are produced lazily, so a corrupt or truncated `.roi` raised during iteration rather than from the read call and escaped the per-bin error handling as an unhandled Python traceback, discarding the results of every bin already processed. Such failures are now reported as a per-bin error like any other.
* Corrected the `vol2C_lgdiatom()` documentation, which incorrectly stated the relationship applied to diatoms > 2000 micron^3 (the Menden-Deuer and Lessard 2000 large-diatom equation is for cells > 3000 micron^3).
* Examples that call remote services (`ifcb_download_dashboard_data()`, `ifcb_download_dashboard_metadata()`, `ifcb_match_taxa_names()` and `ifcb_is_diatom()`) are now wrapped in `try()` so they degrade gracefully when the service is unreachable.

# iRfcb 0.9.0

## New features

* Added `ifcb_extract_features()`, which computes the slim feature set (version 4) and blob masks from raw IFCB data by calling the WHOI [`ifcb-features`](https://github.com/WHOIGit/ifcb-features) Python package. Features (`<bin>_features_v4.csv`) and blobs (`<bin>_blobs_v4.zip`) are written to separate, user-specified folders, existing outputs are skipped unless `overwrite = TRUE`, and bins can be processed in parallel via `parallel = TRUE` / `n_cores`. A `cli` progress bar advances as each bin is processed (for both sequential and parallel runs), and interrupting the function (e.g. ESC / Stop) reliably terminates the parallel worker processes instead of leaving them writing files in the background.
* Added `features` and `features_ref` arguments to `ifcb_py_install()` to optionally install the WHOI `ifcb-features` package (and its dependencies) from GitHub, as required by `ifcb_extract_features()`. By default the latest published release is installed; `features_ref` can pin a specific tag or install the development branch. When installing into an existing virtual environment, the install is skipped if `ifcb-features` already imports successfully (unless `features_ref` is supplied), avoiding a slow repeated download.
* Added a new `dataset_name` argument to `ifcb_list_dashboard_bins()` to optionally restrict the listing to bins from a specific dataset. This argument remains useful for self-hosted dashboard instances that have not yet updated to remove the `api/list_bins` endpoint.
* Added support for the `IRFCB_PYTHON_VENV` environment variable. When `USE_IRFCB_PYTHON = "TRUE"`, you can now set `IRFCB_PYTHON_VENV` to either a named virtualenv or a full path to a venv directory to control which Python environment is activated on package load. If unset, the previous behavior of auto-discovering a venv named `iRfcb` is retained.

## Deprecations

* `ifcb_list_dashboard_bins()` is deprecated. The upstream IFCB Dashboard removed the `api/list_bins` endpoint on 2026-03-08 ([WHOIGit/ifcbdb@8c5839f1](https://github.com/WHOIGit/ifcbdb/commit/8c5839f1)), so the function no longer works against the WHOI dashboard and other deployments tracking upstream. Use `ifcb_download_dashboard_metadata()` instead, which retrieves the same per-bin information from the still-supported `api/export_metadata` endpoint.

## Minor improvements and fixes

* Additional Python packages installed into an existing virtual environment by `ifcb_py_install()` are now installed with a clean dependency resolution (no longer using pip `--ignore-installed`). Previously, installing packages with pinned, compiled dependencies (such as `ifcb-features`/`pyifcb`, which pin exact `numpy`/`scipy`/`pandas` versions) could layer incompatible builds on top of existing ones and corrupt the environment (e.g. `ImportError: cannot import name '_spropack'`).
* The default `gradio_url` for `ifcb_classify_images()`, `ifcb_classify_sample()`, `ifcb_classify_models()`, and `ifcb_save_classification()` has changed from the Hugging Face example Space (`https://irfcb-classify.hf.space`) to a more stable instance hosted on SciLifeLab Serve (`https://ifcb.serve.scilifelab.se`). The default `model_name` has correspondingly been updated to `"SMHI NIVA SYKE SAMS SZN ResNet 50 V6"`. The Hugging Face Space remains documented as a free alternative for testing and demonstration.
* Migrated all user-facing messaging from base R (`stop()`, `warning()`, `message()`) and `utils::txtProgressBar` to the `cli` package. Errors, warnings, and informational messages now use semantic inline markup (file paths, argument names, function names, values) and pluralization. Progress bars are rendered via `cli::cli_progress_bar()`. `cli` is now an `Imports` dependency.

# iRfcb 0.8.1

## Bug fixes

* Fixed `adc_get_roi_columns()` failing to detect ROI dimension columns for older IFCB instruments (e.g. IFCB110) where HDR files use different column name casing (`ROIwidth`/`ROIheight`/`start_byte`) compared to newer instruments (`RoiWidth`/`RoiHeight`/`StartByte`). Column matching is now case-insensitive and positional fallback uses column indices instead of V-prefixed names (#77).

# iRfcb 0.8.0

## New features

* New function `ifcb_classify_images()` to classify one or more pre-extracted IFCB PNG images through a CNN model served by a Gradio application, returning a data frame of predicted class names and confidence scores. Per-class thresholds are applied automatically.
* New function `ifcb_classify_sample()` to classify all images in a raw IFCB sample (`.roi` file) without prior PNG extraction. Internally extracts images to a temporary directory and delegates to `ifcb_classify_images()`.
* New function `ifcb_save_classification()` to classify IFCB samples via Gradio API and save results as HDF5 (`.h5`), MAT (`.mat`), or CSV (`.csv`) files.
* New function `ifcb_classify_models()` to list available CNN models from a Gradio classification server.
* Added HDF5 (`.h5`) and CSV (`.csv`) classification file support to `ifcb_extract_biovolumes()`, `ifcb_extract_classified_images()`, `ifcb_summarize_class_counts()`, `ifcb_summarize_biovolumes()`, and `summarize_TBclass()`, in addition to existing `.mat` support.

## Breaking changes

* Image extraction functions (`ifcb_extract_pngs()`, `ifcb_extract_annotated_images()`, and `ifcb_extract_classified_images()`) now preserve raw pixel values by default (`normalize = FALSE`), producing images comparable to IFCB Dashboard and other standard IFCB software. Previously, pixel values were stretched to the full 0-255 range using min-max normalization. This change can affect classifier training results. Set `normalize = TRUE` to restore the previous behavior (#75).

## Minor improvements and fixes

* `ifcb_create_manual_file()` now writes `class2use_auto` as a numeric matrix, matching the format produced by `ifcb-analysis` (#74).
* Corrected the parameter description of `micron_factor` in `ifcb_psd()` and `ifcb_extract_biovolumes()`.
* Corrected the parameter description of `skip_class` in `ifcb_extract_annotated_images()`.

## Deprecations

* `ifcb_run_image_gallery()` is deprecated in favor of `ClassiPyR::run_app()`. See <https://europeanifcbgroup.github.io/ClassiPyR/> for more information.
* Deprecated arguments:
  * `old_adc` in `ifcb_extract_pngs()`, `ifcb_extract_annotated_images()`, and `ifcb_extract_classified_images()`. ADC format (old IFCB1-6 vs new) is now auto-detected from the HDR file's `ADCFileFormat` parameter and the ADC column count.
  * `mat_files` in `ifcb_extract_biovolumes()` and `ifcb_summarize_biovolumes()` (replaced by `class_files`).
  * `mat_recursive` in `ifcb_extract_biovolumes()` and `ifcb_summarize_biovolumes()` (replaced by `class_recursive`).

# iRfcb 0.7.0

## New features

* New function `ifcb_annotate_samples()` to create manual classification `.mat` files compatible with the `ifcb-analysis` MATLAB repository, using PNG images organized in class named subfolders and a `class2use.mat` file.
* New function `ifcb_zip_images_by_class()` to zip each PNG subfolder with optional random sampling. Useful for preparing class-specific image archives for submission.
* Added a new `diatom_include` argument to `ifcb_extract_biovolumes()` and `ifcb_is_diatom()` for manually forcing specific taxa to be treated as diatoms (overrides WoRMS classification).
* Added a new `timestamp_param` argument to `ifcb_get_ferrybox_data()` allowing the Ferrybox timestamp column to be specified dynamically instead of being hard coded.
* Added a new `max_time_diff_min` argument to `ifcb_get_ferrybox_data()` controlling the maximum allowed time difference in minutes when matching Ferrybox data to requested timestamps.
* Added a new `biovolume_only` argument to `ifcb_read_features()` to allow reading only biovolume related columns, improving performance for large feature tables.
* Added a new `add_trailing_numbers` argument to `ifcb_extract_annotated_images()` to control whether a zero-padded numeric suffix based on the manual class index is appended to class names in the output filenames.
* Added a new `include_classes` argument to `ifcb_prepare_whoi_plankton()` to allow explicit selection of classes to include during processing.

## Minor improvements and fixes

* Runnable examples are now wrapped in `\donttest{}` instead of `\dontrun{}`.
* Timestamp matching in `ifcb_get_ferrybox_data()` is now more flexible and can fall back to the closest available Ferrybox observation within the specified time window when no exact or rounded match is found.
* `ifcb_summarize_biovolumes()` and `ifcb_extract_biovolumes()` are now more flexible and accept individual `.mat` files in addition to folders.
* Improved performance of `ifcb_extract_biovolumes()` and `ifcb_summarize_biovolumes()`.
* All data frame outputs are now consistently returned as tibbles.
* Updated IFCB example in `ifcb_get_ecotaxa_example()`.
* Moved vignettes that required internet access to package articles to improve CRAN check reliability.
* Improved error handling across functions, with clearer and more consistent messages.
* EEA coastline data are now obtained from EEA map services, replacing direct file server downloads that were unstable.
* Test data are sourced from GitHub when not available on Figshare.
* `ifcb_create_manual_file()` and `ifcb_create_empty_manual_file()` now correctly handles `NaN` values in the `classlist`.

## Deprecations

* `ifcb_create_empty_manual_file()` has been renamed to `ifcb_create_manual_file()`.
* `ifcb_match_taxa_names()` is now superseded by `SHARK4R::match_worms_taxa()`.
* Deprecated arguments:
  * `mat_folder` in `ifcb_summarize_biovolumes()` and `ifcb_extract_biovolumes()` (replaced by `mat_files`).
  * `expected_checksum` in `ifcb_download_test_data()`.

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

* Introduced unit testing with `testthat` for improved stability.
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
