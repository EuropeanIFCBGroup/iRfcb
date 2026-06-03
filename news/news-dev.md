# Version dev

## iRfcb (development version)

### New features

- Added a new `dataset_name` argument to
  [`ifcb_list_dashboard_bins()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_list_dashboard_bins.md)
  to only optionally only list bins from a specific dataset.

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
