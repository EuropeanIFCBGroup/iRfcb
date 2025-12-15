# Version dev

## iRfcb (development version)

### Minor improvements and fixes

- Runnable examples are now wrapped in `\donttest{}` instead of
  `\dontrun{}`.
- Added a new `timestamp_param` argument to
  [`ifcb_get_ferrybox_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_ferrybox_data.md)
  allowing the Ferrybox timestamp column to be specified dynamically
  instead of being hard coded.
- Added a new `max_time_diff_min` argument to
  [`ifcb_get_ferrybox_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_ferrybox_data.md)
  controlling the maximum allowed time difference in minutes when
  matching Ferrybox data to requested timestamps.
- Timestamp matching in
  [`ifcb_get_ferrybox_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_get_ferrybox_data.md)
  is now more flexible and can fall back to the closest available
  Ferrybox observation within the specified time window when no exact or
  rounded match is found.
