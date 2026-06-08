# Version dev

## iRfcb (development version)

### New features

- Added
  [`ifcb_extract_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_features.md),
  which computes the slim feature set (version 4) and blob masks from
  raw IFCB data by calling the WHOI
  [`ifcb-features`](https://github.com/WHOIGit/ifcb-features) Python
  package. Features (`<bin>_features_v4.csv`) and blobs
  (`<bin>_blobs_v4.zip`) are written to separate, user-specified
  folders, existing outputs are skipped unless `overwrite = TRUE`, and
  bins can be processed in parallel via `parallel = TRUE` / `n_cores`. A
  `cli` progress bar advances as each bin is processed (for both
  sequential and parallel runs), and interrupting the function (e.g. ESC
  / Stop) reliably terminates the parallel worker processes instead of
  leaving them writing files in the background.
- Added `features` and `features_ref` arguments to
  [`ifcb_py_install()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md)
  to optionally install the WHOI `ifcb-features` package (and its
  dependencies) from GitHub, as required by
  [`ifcb_extract_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_features.md).
  By default the latest published release is installed; `features_ref`
  can pin a specific tag or install the development branch. When
  installing into an existing virtual environment, the install is
  skipped if `ifcb-features` already imports successfully (unless
  `features_ref` is supplied), avoiding a slow repeated download.
- Added a new `dataset_name` argument to
  [`ifcb_list_dashboard_bins()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_list_dashboard_bins.md)
  to optionally restrict the listing to bins from a specific dataset.
  This argument remains useful for self-hosted dashboard instances that
  have not yet updated to remove the `api/list_bins` endpoint.
- Added support for the `IRFCB_PYTHON_VENV` environment variable. When
  `USE_IRFCB_PYTHON = "TRUE"`, you can now set `IRFCB_PYTHON_VENV` to
  either a named virtualenv or a full path to a venv directory to
  control which Python environment is activated on package load. If
  unset, the previous behavior of auto-discovering a venv named `iRfcb`
  is retained.

### Deprecations

- [`ifcb_list_dashboard_bins()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_list_dashboard_bins.md)
  is deprecated. The upstream IFCB Dashboard removed the `api/list_bins`
  endpoint on 2026-03-08
  ([WHOIGit/ifcbdb@8c5839f1](https://github.com/WHOIGit/ifcbdb/commit/8c5839f1)),
  so the function no longer works against the WHOI dashboard and other
  deployments tracking upstream. Use
  [`ifcb_download_dashboard_metadata()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_download_dashboard_metadata.md)
  instead, which retrieves the same per-bin information from the
  still-supported `api/export_metadata` endpoint.

### Minor improvements and fixes

- Additional Python packages installed into an existing virtual
  environment by
  [`ifcb_py_install()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md)
  are now installed with a clean dependency resolution (no longer using
  pip `--ignore-installed`). Previously, installing packages with
  pinned, compiled dependencies (such as `ifcb-features`/`pyifcb`, which
  pin exact `numpy`/`scipy`/`pandas` versions) could layer incompatible
  builds on top of existing ones and corrupt the environment
  (e.g. `ImportError: cannot import name '_spropack'`).
- The default `gradio_url` for
  [`ifcb_classify_images()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_images.md),
  [`ifcb_classify_sample()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_sample.md),
  [`ifcb_classify_models()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_classify_models.md),
  and
  [`ifcb_save_classification()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_save_classification.md)
  has changed from the Hugging Face example Space
  (`https://irfcb-classify.hf.space`) to a more stable instance hosted
  on SciLifeLab Serve (`https://ifcb.serve.scilifelab.se`). The default
  `model_name` has correspondingly been updated to
  `"SMHI NIVA SYKE SAMS SZN ResNet 50 V6"`. The Hugging Face Space
  remains documented as a free alternative for testing and
  demonstration.
- Migrated all user-facing messaging from base R
  ([`stop()`](https://rdrr.io/r/base/stop.html),
  [`warning()`](https://rdrr.io/r/base/warning.html),
  [`message()`](https://rdrr.io/r/base/message.html)) and
  [`utils::txtProgressBar`](https://rdrr.io/r/utils/txtProgressBar.html)
  to the `cli` package. Errors, warnings, and informational messages now
  use semantic inline markup (file paths, argument names, function
  names, values) and pluralization. Progress bars are rendered via
  [`cli::cli_progress_bar()`](https://cli.r-lib.org/reference/cli_progress_bar.html).
  `cli` is now an `Imports` dependency.
