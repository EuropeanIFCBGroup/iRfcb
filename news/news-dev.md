# Version dev

## iRfcb (development version)

### New features

- Added a new `diatom_include` argument to
  [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  and
  [`ifcb_is_diatom()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_is_diatom.md)
  for manually forcing specific taxa to be treated as diatoms (overrides
  WoRMS classification).
- Added a new `timestamp_param` argument to
  [`ifcb_get_ferrybox_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_ferrybox_data.md)
  allowing the Ferrybox timestamp column to be specified dynamically
  instead of being hard coded.
- Added a new `max_time_diff_min` argument to
  [`ifcb_get_ferrybox_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_ferrybox_data.md)
  controlling the maximum allowed time difference in minutes when
  matching Ferrybox data to requested timestamps.
- Added a new `biovolume_only` argument to
  [`ifcb_read_features()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_features.md)
  to allow reading only biovolume related columns, improving performance
  for large feature tables.

### Minor improvements and fixes

- Runnable examples are now wrapped in `\donttest{}` instead of
  `\dontrun{}`.
- Timestamp matching in
  [`ifcb_get_ferrybox_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_ferrybox_data.md)
  is now more flexible and can fall back to the closest available
  Ferrybox observation within the specified time window when no exact or
  rounded match is found.
- [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
  and
  [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  are now more flexible and accept individual `.mat` files in addition
  to folders.
- Improved performance of
  [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
  and
  [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md).

### Deprecations

- Deprecated arguments:
  - `mat_folder` in
    [`ifcb_summarize_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_summarize_biovolumes.md)
    and
    [`ifcb_extract_biovolumes()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_extract_biovolumes.md)
    (replaced by `mat_files`).
