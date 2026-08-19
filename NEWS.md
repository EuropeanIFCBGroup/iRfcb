# iRfcb 0.10.0

## New features

* Added support for the per-ROI `cell_count` data produced by the diatom chain counter (Groves et al. 2026, [doi:10.1093/plankt/fbaf064](https://doi.org/10.1093/plankt/fbaf064)) through the [`ifcb-pytorch-classify`](https://github.com/nodc-sweden/ifcb-pytorch-classify) pipeline and stored in `.mat`, `.h5` and `.csv` classification files. Abundance can now be reported in cells rather than images, so a chain of eight cells counts as eight.
  * New `ifcb_summarize_cell_counts()` reports cell abundance and chain-length statistics (`n_counted`, `mean`, `median`, `max`, `sd`) per sample and class, and abundance per liter when given an `hdr_folder`. `n_counted` is the number of ROIs the chain counter measured, including those it found to hold a single cell.
  * `ifcb_extract_biovolumes()` and `ifcb_summarize_biovolumes()` gain a `use_cell_counts` argument. When `TRUE`, `ifcb_summarize_biovolumes()` adds a `cell_counts` column, and `cell_counts_per_liter` when an `hdr_folder` is supplied.
  * `single_cell_values` (default `c(-1, 0)`) sets which `cell_count` values are read as one cell: by default the ROIs the counter skipped (`-1`) and those where it found no cells (`0`). Any other value is used as it stands.
  * `cell_counts` is `NA` rather than `0` for a sample whose classification file carries no `cell_count` data, since a zero would look the same as a taxon that was genuinely absent. `counts` still reports the images, and a warning says how many files were affected. A missing value inside a file that does carry `cell_count` data, such as a blank CSV cell, also makes the affected sample's `cell_counts` `NA`, and is likewise reported with a warning naming the samples and how many ROIs were missing a value.
  * The SHARK column template (`ifcb_get_shark_colnames()` and `ifcb_get_shark_example()`) gains an `IMAGE_COUNT` column after `COUNT`. Dividing `COUNT` by `IMAGE_COUNT` gives the average cells per image. That is not the same as `mean_chain_length`, which averages only over the images the counter actually measured, whereas the ratio includes the images it never looked at.
* `ifcb_extract_biovolumes()` and `ifcb_summarize_biovolumes()` gain two arguments controlling how the Menden-Deuer and Lessard (2000) carbon equations are applied. Both keep the previous behavior by default, so carbon values do not change unless you set one.
  * `diatom_equation` chooses the diatom equation. `"large"` (the default) uses the large-diatom equation, as `ifcb-analysis` does; `"all"` uses the all-sizes equation, which gives small cells more carbon; `"auto"` chooses per ROI by volume, keeping each equation inside the size range it was fitted for. The two disagree at the 3000 micron^3 boundary, predicting about 190 against 135 pgC, so `"auto"` makes carbon fall as a cell grows past it. That is why it is not the default. New helpers `vol2C_diatom()` and `vol2C_diatom_auto()` are exported.
  * `carbon_conversion` chooses the volume the equation is applied to. The equations are fitted per cell, but an IFCB biovolume covers a whole image, which for a chain-forming diatom is the whole chain, so converting the chain volume in one go under-reports carbon. `"cell"` converts per cell and sums over the chain, and requires `use_cell_counts = TRUE`. See `?ifcb_extract_biovolumes` for how large the difference gets.
  * Biovolume itself is unchanged by either argument. It is still measured per image, so a chain of small cells still gives one large biovolume.
* Added `ifcb_qc_sample()`, which checks raw IFCB samples (the `.hdr`, `.adc` and `.roi` triplet) and returns one row of QC metrics and flags per sample. It looks for missing files, ROI counts that disagree with the header, truncated `.roi` files, run times that contradict the ADC, implausible analyzed volumes, and ROI dimensions that failed to parse. Bead runs, empty samples, oversized `.roi` files and high recorded humidity or temperature are reported as advisory flags and do not fail `qc_pass`. A check that cannot be run on a sample is reported as `NA` and does not fail it either, so legacy headers without a `roiCount` field are not penalized for a check that could never apply. The function accepts a directory, sample names with a `data_folder`, or explicit file paths, and needs no Python.
* `ifcb_extract_features()` gains a `multiblob` argument. With `multiblob = TRUE` it additionally writes `multiblob/<bin>_multiblob_v4.csv` files inside the features folder, holding the per-blob features of every blob in a region of interest with more than one blob (the slim table describes only the largest, plus `summed*` totals), one row per blob with `roi_number`, `blob_number` and 18 morphological columns. This is the sidecar output `ifcb-features` introduced in v1.2.0, which is also the minimum version required; the function stops with a clear error on older releases, since they never compute per-blob features. As upstream, a bin in which no ROI has more than one blob gets no sidecar file, so the file's presence means the bin genuinely holds multi-blob ROIs; the skip logic reads the `numBlobs` column of a bin's existing feature CSV to tell whether a sidecar is expected, so a re-run with `multiblob = TRUE` over a directory extracted without it re-extracts only the bins that actually need one, without `overwrite = TRUE`. `ifcb_read_features()` reads these files as it stands, with `multiblob = TRUE`; its multiblob filter now matches on the file name rather than the whole path, so a feature folder located somewhere under a directory with `multiblob` in its name no longer reads as all-multiblob (or, with the default `multiblob = FALSE`, as empty).

## Minor improvements and fixes

* `ifcb_save_classification()` now reports a missing `roi_file` before requiring `hdf5r`. Its tests no longer depend on the suggested `hdf5r` package, fixing the CRAN check failures on platforms without it.
* Tests using `use_python = TRUE` now skip when `scipy` is unavailable, instead of letting `reticulate` download an ephemeral Python environment mid-check.
* The native MAT reader no longer runs out of memory on a truncated compressed section when R is built against zlib-ng (the system zlib on recent Fedora), where `memDecompress()` grows its buffer indefinitely instead of erroring. Such sections now fall through to the incremental recovery path as intended.
* `ifcb_classify_images()`, `ifcb_classify_sample()` and `ifcb_classify_models()` now retry transient network failures (dropped connections and HTTP 429/5xx responses) up to four times with exponential backoff. A brief server outage, such as the hosted SciLifeLab Serve instance restarting, used to fail every image it touched with `Couldn't connect to server`, leaving a run of `NA` rows mid-sample. Set `options(iRfcb.gradio_max_tries = )` to change the number of attempts; a malformed value for either retry option is reported by name rather than surfacing as a cryptic error elsewhere.
* `ifcb_extract_biovolumes()`, `ifcb_summarize_biovolumes()` and `ifcb_summarize_cell_counts()` now stop with an error when one sample resolves to more than one classification file, for example a folder holding both a `.mat` and an `.h5` for the same sample, and name the samples involved. Previously both files were read and joined, which silently doubled that sample's counts, biovolume and carbon.
* The classification-file readers no longer trip over non-class `.csv` files in a class directory. An IFCB Dashboard `class_scores` export (`{sample}_class.csv`) could be picked up and then fail with a confusing `Unknown or uninitialised column: 'class'` error followed by a WoRMS 400 response. Such files are now skipped with a warning naming the missing columns when a folder is supplied, and raise a clear error when passed explicitly. A *valid* label file named `{sample}_class.csv` now resolves to the same sample as `{sample}.csv`, so it joins under the right sample instead of appearing as a phantom `{sample}_class` sample no HDR file could match. Relatedly, an `hdr_folder` whose files match none of the classified samples now warns and reports `NA` per-liter values instead of aborting with an unexplained join error, and the `classifier` column read from `.mat` files is a plain character vector rather than a one-column matrix.
* `ifcb_is_diatom()` gains a `details` argument. When `TRUE` it returns a data frame with the WoRMS class resolved for each taxon instead of a logical vector. Use it to find genus homonyms, that is diatom genera such as `Navicula` or `Actinocyclus` that share a name with an animal and so resolve to a non-diatom class, then add those taxa to `diatom_include`. A class list in which nothing resolves in WoRMS at all, such as one holding only labels like `unclassified` or `detritus`, returns `NA` classes instead of failing.
* `ifcb_extract_biovolumes()` and `ifcb_summarize_biovolumes()` report the diatom classification more clearly when `verbose = TRUE`. The classes treated as diatoms are listed in full, classes missing from WoRMS are listed separately, and the long list of non-diatoms is reduced to a count. Previously that list was printed and truncated, making it hard to see whether a class you expected to be a diatom had been recognized as one.
* Creating and editing MATLAB `ifcb-analysis` manual classification files no longer requires Python. `ifcb_create_class2use()`, `ifcb_create_manual_file()`, `ifcb_adjust_classes()`, `ifcb_correct_annotation()`, `ifcb_replace_mat_values()` and the `format = "mat"` output of `ifcb_save_classification()` write `.mat` files with a native R implementation, producing the same output as the previous `scipy.io.savemat` approach. The wrapper functions that call them are Python-free as a result, so `scipy` and `numpy` are no longer needed for annotation work.
* Removed `R.matlab` as a dependency. Reading `.mat` files without Python now uses the native R reader as well, which decodes MATLAB UTF-16 text correctly, so accented class or path names survive where `R.matlab::readMat()` could mangle them. It reads every numeric storage type MATLAB uses to hold an array compactly (`int8` through `uint32`, `single` and `double`), preserving each across a read-write round-trip, including values at the signed and unsigned 32-bit limits that R cannot hold in an integer. Multi-row character matrices, such as the `filelistTB` sample list that `ifcb-analysis` summary files hold as one fixed-width row per sample, are read as one string per row, so `ifcb_read_summary()` handles multi-sample summaries the same way with either reader. The reader also refuses input it cannot represent faithfully, naming the variable and the reason, reports a truncated file instead of reading it back quietly padded with zeros, and rejects declared dimensions that disagree with the data carried rather than recycling values to fill them out. The writer applies the same standard: a value that does not fit the storage type a variable was read with is refused rather than silently wrapped, and `ifcb_correct_annotation()` and `ifcb_replace_mat_values()` widen a classlist to double when a new class id outgrows the compact integer type MATLAB stored it in. All of this matters because `ifcb_adjust_classes()` and `ifcb_correct_annotation()` write what they read back over the same file. One thing it tolerates rather than refuses: a compressed section that ends without its stream terminator, which some classification files written by MATLAB contain. The data in those is intact, so it is decoded incrementally and read, with a warning naming the file. `R.matlab` has moved to `Suggests`.
  * Note that this makes reading stricter than in 0.9.0, so a file that used to open may now stop with an error. `R.matlab` would read a `.mat` containing a struct, an object, a sparse or complex array, a logical array, more than two dimensions, or a MATLAB string array (as saved by `class2use = ["a" "b"]` in a recent MATLAB release), and iRfcb would then quietly write back something that was not what it read. Those files are now named and refused instead. The formats iRfcb itself deals with are unaffected: manual files, `class2use` files and classifier output written by MATLAB `ifcb-analysis` or the Python pipelines all read as before. If you do have a third-party file that no longer opens, `ifcb_get_mat_names()` and `ifcb_get_mat_variable()` read it with `use_python = TRUE`, which goes through `SciPy` instead, once a Python environment has been set up with `ifcb_py_install()`.
* `ifcb_extract_features()` now works with both raw-data readers used by WHOI [`ifcb-features`](https://github.com/WHOIGit/ifcb-features). Release v1.1.0 swapped `pyifcb` for the lighter [`ifcbkit`](https://github.com/WHOIGit/ifcbkit), which broke `iRfcb` against v1.1.0 and later, and since `ifcb_py_install(features = TRUE)` installs the newest release by default this affected new installations. Either reader now works, and a new `backend` argument (or the `IRFCB_IFCB_BACKEND` environment variable) pins one. Measurements are unaffected for the D-style bins current instruments produce. The readers differ only on older I-style bins and on ROIs with zero height, so pin a reader if you need results comparable to an earlier I-style run. Installing v1.1.0 or later also drops the `h5py` dependency, which had restricted which Python versions could be used.
* `ifcb_extract_features()` now works with `ifcb-features` v1.2.0, which changed what `compute_features` returns to carry the new multiblob output. Without this change every ROI failed to unpack, and because a failed ROI is skipped rather than fatal, the extraction would report success while writing feature files holding only `roi_number` and no blob images. All earlier `ifcb-features` releases still work, and the extracted measurements are unchanged. The per-blob multiblob rows themselves are not used, since they are not part of the slim feature set.
* Fixed `ifcb_extract_features()` writing text instead of numbers into the `Eccentricity`, `MajorAxisLength` and `MinorAxisLength` columns of `<bin>_features_v4.csv`. On `numpy` 2.3 and later these values arrived as complex numbers and were written as strings such as `(0.797+0j)`, quietly turning three numeric columns into text. They are numeric again and the values are unchanged, with one exception worth knowing about for size spectra and biovolume sums: a degenerate, one-pixel-wide blob is now measured as `0` rather than `NaN`, so it contributes a zero instead of a missing value you could filter out. That matches upstream `ifcb-features` and the `summed*` columns. To reproduce an earlier run, pin `ifcb-features` v1.0.0 or `numpy < 2.3`; see `?ifcb_py_install`.
* `ifcb_extract_features()` no longer prints a `FutureWarning` for every region of interest from recent `scikit-image` releases, which had been breaking up the progress bar. `ifcb_py_install(features = TRUE)` also holds `scikit-image` below 0.28, the release that removes the deprecated functions `ifcb_features` calls.
* `ifcb_extract_features()` no longer discards a whole sequential run when one bin cannot be read. A corrupt or truncated `.roi` used to escape as a Python traceback, taking every bin already processed with it. Such a bin is now reported as a per-bin error like any other.
* `ifcb_extract_features()` gains a `feature_tag` argument controlling the feature file name. The default (`"features"`) writes `<bin>_features_v4.csv` as before; `"fea"` writes `<bin>_fea_v4.csv`, the name the IFCB Dashboard serves.
* Fixed `ifcb_volume_analyzed_from_adc()` failing when given more than one ADC file, or a URL. The existence check was not vectorized, so a vector of files stopped with `the condition has length > 1` even though the rest of the function already looped over them, and it rejected URLs outright even though the rest of the function handles remote files. Local paths are now checked one by one, with every missing path reported at once, and URLs pass straight through.
* Realigned `ifcb_get_runtime()` and `ifcb_volume_analyzed_from_adc()` with their MATLAB `ifcb-analysis` counterparts (`IFCBxxx_readhdr.m`, `IFCB_volume_analyzed_fromADC.m`), fixing five places where the R port had drifted from the reference.
  * Legacy headers, which carry `run time` and `inhibit time` on a single line, were read with the inhibit time set to a copy of the run time, so every legacy sample reported a look time of zero and an analyzed volume of zero. The two values are now read from their own positions on the line, as the reference does.
  * Header keys are matched at the start of the line, as the reference's `strmatch` does. A header holding an extra key that merely ends in `runtime:` used to make `ifcb_get_runtime()` return two values, which `ifcb_qc_sample()` then recycled into a duplicated, failing row for that sample.
  * The startup-offset correction for instruments whose run/inhibit clocks lead the ADC timestamp called `mode()`, which in R is `base::mode()` and not the statistical mode the MATLAB reference computes, so the correction always failed with `non-numeric argument to binary operator` on exactly the instruments it was written for.
  * Corrupted inhibit-time rows are repaired the way the reference repairs them, from the last well-behaved row plus one typical increment per bad row, instead of using the corrupted final value as it stands. The timestamp-derived run-time fallback is now applied when the run-time clock disagrees with it, where previously it was computed and then overwritten.
  * A volume that cannot be derived, for example from an ADC without run/inhibit time columns, is now `NA` with a warning instead of a silent `0`, matching the `NaN` the reference returns. A zero looked exactly like an instrument that analyzed no water, and made `ifcb_qc_sample()` fail such samples for an implausible volume.
* `ifcb_correct_annotation()` and `ifcb_replace_mat_values()` now check their inputs and fail with a message you can act on. An out-of-range ROI number or `column_index` reports the value and the valid range instead of `subscript out of bounds`, a classlist with fewer than two columns is reported as such, and a missing input file or a `.mat` file without a `classlist` variable is named explicitly. `ifcb_adjust_classes()` likewise passes the reader's own refusal message through when it skips a file, instead of relabeling every problem "empty or corrupted".
* Fixed `use_python = TRUE` being ignored when Python and `SciPy` were in fact available. `ifcb_get_mat_names()`, `ifcb_get_mat_variable()`, `ifcb_read_summary()`, `ifcb_count_mat_annotations()`, `ifcb_extract_annotated_images()` and `ifcb_adjust_classes()` decided whether they could use Python by looking for `scipy` in `reticulate::py_list_packages()`, and fell back to the R reader without saying so when it was not listed. Two things went wrong with that: on a `conda` environment the listing reports conda's own base packages, so an installed and perfectly importable `scipy` was absent from it; and the check did not initialize Python, so in a fresh session it failed whatever the environment held. Availability is now settled by asking Python to import the module, and when `use_python = TRUE` is requested but Python with `scipy` is genuinely unavailable, the fallback to the R reader is announced with a warning (once per session) instead of happening silently. This matters most when a `.mat` file cannot be read by the R reader, since `use_python = TRUE` is the documented way to read it.
* Clarified the deprecation of `ifcb_read_hdr_data(hdr_folder = )` and `ifcb_annotate_batch(adc_folder = )`. Both read as though the package had renamed `hdr_folder` and `adc_folder` everywhere, which it has not: those two functions were changed to accept a vector of file paths, so their argument was renamed to match. Functions that genuinely take a single directory, such as `ifcb_psd()`, `ifcb_summarize_biovolumes()`, `ifcb_summarize_cell_counts()` and `ifcb_annotate_samples()`, keep `hdr_folder` and `adc_folder` and are not deprecated.
* Corrected the `vol2C_lgdiatom()` documentation, which said the relationship applied to diatoms above 2000 micron^3. The Menden-Deuer and Lessard (2000) large-diatom equation is for cells above 3000 micron^3.
* Examples that call remote services (`ifcb_download_dashboard_data()`, `ifcb_download_dashboard_metadata()`, `ifcb_match_taxa_names()` and `ifcb_is_diatom()`) are now wrapped in `try()` so they fail gracefully when the service is unreachable.

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
