# Quality-control a raw IFCB sample (hdr/adc/roi triplet)

Validates the integrity and self-consistency of one or more raw IFCB
samples and returns a tidy tibble of QC metrics and flags, one row per
sample. Each sample is expected to consist of the standard IFCB file
triplet sharing a base name: a header (`.hdr`), an ADC table (`.adc`),
and the raw image data (`.roi`).

## Usage

``` r
ifcb_qc_sample(
  sample,
  data_folder = NULL,
  max_ml = NULL,
  volume_tolerance = 0.05,
  runtime_tolerance = 0.02,
  max_roi_mb = NULL,
  max_humidity = NULL,
  max_temperature = NULL,
  flowrate = 0.25
)
```

## Arguments

- sample:

  Sample(s) to check. Either a single directory (all `.adc` files within
  are discovered recursively), or a character vector of sample base
  names or paths (with or without a `.hdr`/`.adc`/`.roi` extension).
  When `data_folder` is supplied, bare sample names are resolved against
  it.

- data_folder:

  Optional directory in which to locate the triplet files when `sample`
  is given as bare sample names. Searched recursively.

- max_ml:

  Optional fixed upper bound (in millilitres) for a plausible analyzed
  volume, applied to every sample. Default `NULL` derives the ceiling
  per sample from the header syringe volume (`SyringeSampleVolume`,
  falling back to `syringeSize`, then the 5 mL IFCB standard) scaled by
  `volume_tolerance`. Set this only to override that instrument-reported
  value.

- volume_tolerance:

  Fractional tolerance added to the derived syringe volume ceiling
  (default `0.05`, i.e. 5%) to absorb estimation noise in the analyzed
  volume. Ignored when `max_ml` is supplied.

- runtime_tolerance:

  Fractional slack by which the ADC's last-trigger run time may exceed
  the header's total run time before `runtime_consistent` is set to
  `FALSE` (default `0.02`, i.e. 2%).

- max_roi_mb:

  Optional numeric upper bound (in megabytes, where 1 MB = 1024^2 bytes)
  for the `.roi` file size. When supplied, samples whose `.roi` exceeds
  this size are flagged in the advisory `roi_oversized` column (e.g.
  `max_roi_mb = 5` for 5 MB). Default `NULL` disables the check
  (`roi_oversized` is `NA`).

- max_humidity:

  Optional numeric threshold (percent) for the header's recorded
  `humidity`. Samples above it are flagged in the advisory
  `humidity_high` column. Default `NULL` disables the check.

- max_temperature:

  Optional numeric threshold (degrees, as recorded by the instrument)
  for the header's `temperature`. Samples above it are flagged in the
  advisory `temperature_high` column. Default `NULL` disables the check.

- flowrate:

  Syringe flow rate (millilitres per minute) passed to
  [`ifcb_volume_analyzed()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_volume_analyzed.md).
  Default `0.25`.

## Value

A tibble with one row per sample containing the resolved file paths, QC
metrics, boolean QC flags, and an overall `qc_pass` column.

## Details

The checks build directly on the package's existing readers
([`ifcb_read_hdr_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_hdr_data.md),
`read_adc_columns()`,
[`ifcb_volume_analyzed()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_volume_analyzed.md))
cover four areas:

- Triplet completeness:

  Whether all of `.hdr`, `.adc`, and `.roi` are present
  (`files_complete`).

- ROI count consistency:

  The number of imaged ROIs in the ADC (rows with a non-zero ROI width)
  must equal the header's `roiCount` (`roi_count_match`). Note that the
  ADC row count is **not** compared to `triggerCount`: depending on the
  ADC format a single trigger may yield several ROIs, so `triggerCount`
  is reported but not used as a hard check.

- ROI data completeness:

  The `.roi` file must be at least as large as the last image's end
  offset (`max(StartByte + width * height)`) computed from the ADC. A
  smaller file indicates a truncated or aborted transfer
  (`roi_data_complete`).

- Run time consistency:

  The run time recorded at the ADC's last trigger must not exceed the
  header's total run time (within `runtime_tolerance`), since a trigger
  cannot fire after acquisition has stopped (`runtime_consistent`). A
  header run time materially shorter than the ADC's last trigger points
  to corrupted or truncated header metadata; a run that legitimately
  continued past the last trigger (header run time longer than the
  ADC's) is normal for sparse samples and is not flagged.

- Flow / volume sanity:

  The analyzed volume from
  [`ifcb_volume_analyzed()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_volume_analyzed.md)
  must be positive and not exceed the syringe sample volume
  (`volume_ok`). The ceiling is taken from the header's
  `SyringeSampleVolume` (reported as `syringe_ml`, e.g. 5 mL for a
  standard IFCB), plus `volume_tolerance`, since the analyzed volume can
  never physically exceed the drawn syringe volume. A fixed ceiling can
  be forced with `max_ml`.

Further advisory flags are reported but do **not** affect `qc_pass`, as
they describe valid samples that a user may nonetheless wish to exclude:
`is_bead_run` (a bead/calibration run, detected from the header's
`runBeads` field or a `sampleType` containing "bead"), `is_empty` (no
imaged ROIs), `roi_oversized` (the `.roi` file exceeds `max_roi_mb`,
useful for catching overloaded or anomalous runs), and `humidity_high` /
`temperature_high` (the header's recorded `humidity` / `temperature`
exceed `max_humidity` / `max_temperature`, flagging possible
condensation or overheating). The latter three are only evaluated when
their threshold is supplied; otherwise they are `NA`. The measured
`humidity` and `temperature` are always reported.

`qc_pass` is the conjunction of the integrity checks above
(`files_complete`, `roi_count_match`, `roi_data_complete`,
`runtime_consistent`, `volume_ok`). A check that cannot be evaluated for
a given sample is reported as `NA` and treated as *not applicable*: it
does not fail `qc_pass`. This matters for legacy IFCB headers, which
omit the post-run `roiCount` summary field (so `roi_count_match` is
`NA`); such samples can still pass on the checks that do apply. Only a
check that actually evaluates to `FALSE` fails the sample.
`files_complete` and `volume_ok` are always `TRUE`/`FALSE` (never `NA`)
and so always count.

## References

Sosik, H. M. and Olson, R. J. (2007), Automated taxonomic classification
of phytoplankton sampled with imaging-in-flow cytometry. Limnol.
Oceanogr: Methods 5, 204-216.

## See also

[`ifcb_read_hdr_data()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_hdr_data.md)
[`ifcb_volume_analyzed()`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_volume_analyzed.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Check every sample in a data directory
qc <- ifcb_qc_sample("data/raw")

# Keep only clean, non-bead samples for analysis
dplyr::filter(qc, qc_pass, !is_bead_run)
} # }
```
