# Extract Slim Features and Blobs from IFCB Data

This function computes the "slim" feature set (version 4) and blob masks
from raw Imaging FlowCytobot (IFCB) data by calling the WHOI
`ifcb-features` Python package. For each bin it writes a feature table
(`<bin>_features_v4.csv`, 30 morphological features per region of
interest) and an archive of binary blob masks (`<bin>_blobs_v4.zip`, one
1-bit PNG per ROI). Features and blobs are written to separate,
user-specified directories.

## Usage

``` r
ifcb_extract_features(
  data_folder,
  features_folder,
  blobs_folder,
  bins = NULL,
  parallel = FALSE,
  n_cores = NULL,
  overwrite = FALSE,
  feature_tag = c("features", "fea"),
  verbose = TRUE
)
```

## Arguments

- data_folder:

  The path to a directory containing raw IFCB data (`.roi`, `.adc` and
  `.hdr` files). The directory is searched recursively by `pyifcb`, so
  nested data structures are supported.

- features_folder:

  The path to the directory where the `<bin>_features_v4.csv` files will
  be written. Created if it does not exist.

- blobs_folder:

  The path to the directory where the `<bin>_blobs_v4.zip` files will be
  written. Created if it does not exist.

- bins:

  An optional character vector of bin names (e.g.
  `"D20220522T003051_IFCB134"`) to restrict processing to a subset of
  bins. If `NULL` (default), all bins found in `data_folder` are
  processed.

- parallel:

  A logical indicating whether to process bins in parallel. Default is
  `FALSE`.

- n_cores:

  An integer specifying the number of parallel workers to use when
  `parallel = TRUE` (worker processes on Linux, threads on Windows and
  macOS; see Details). If `NULL` (default),
  `parallel::detectCores() - 1` workers are used. Ignored when
  `parallel = FALSE`.

- overwrite:

  A logical indicating whether to overwrite existing feature and blob
  files. If `FALSE` (default), bins whose outputs already exist are
  skipped.

- feature_tag:

  A string controlling the token between the bin lid and the version in
  the feature file name. `"features"` (default) writes
  `<bin>_features_v4.csv` (the upstream `ifcb-features` convention);
  `"fea"` writes `<bin>_fea_v4.csv`, the name the IFCB Dashboard
  (`ifcbdb` / `pyifcb`'s `FeaturesDirectory`) searches for. Use `"fea"`
  when the output is destined for an IFCB Dashboard instance; remember
  the dataset directory there must be registered with product version 4
  to match the `_v4` suffix. The blob archive name
  (`<bin>_blobs_v4.zip`) is unaffected.

- verbose:

  A logical indicating whether to print progress messages, including a
  progress bar that advances as each bin is processed. Default is
  `TRUE`.

## Value

Invisibly returns a tibble with one row per bin and the columns `bin`,
`status` (`"processed"`, `"skipped"` or `"error"`) and `message`. The
function is primarily called for its side effect of writing feature and
blob files to disk.

## Details

This function wraps the `extract_slim_features` workflow from the
`ifcb-features` Python repository, which can be found at
<https://github.com/WHOIGit/ifcb-features>.

Python and the `ifcb-features` package must be installed to use this
function. The required Python packages can be installed in a virtual
environment using `ifcb_py_install(features = TRUE)`, which additionally
installs `ifcb-features` and its dependencies (`pyifcb`, `phasepack`,
`scikit-image`, `scikit-learn`).

**Python version requirement:** `pyifcb` and its dependencies (notably
`h5py`) must be available as binary wheels for your Python version;
installation will fail if source compilation is required and the build
environment is incompatible. See
<https://github.com/WHOIGit/ifcb-features> for current Python version
requirements, and use `ifcb_py_install(features = TRUE)` to install into
a compatible environment.

Bins are processed sequentially by default. When `parallel = TRUE`, bins
are distributed across `n_cores` workers, which can substantially reduce
runtime for large datasets. Existing outputs are skipped unless
`overwrite = TRUE`, so the function can be re-run to resume an
interrupted extraction.

The parallel backend depends on the platform. On Linux, bins run in
separate worker processes, giving true multi-core parallelism. On
Windows and macOS, where the embedded Python interpreter cannot reliably
spawn worker processes, a thread pool is used instead; because of
Python's Global Interpreter Lock the speedup there is smaller and
depends on how much of the work runs in native (`numpy` /
`scikit-image`) code. A further consequence of the thread backend is
that interrupting a run (ESC / Stop) does not halt a bin already being
processed: it finishes and writes its outputs before the run stops.

## See also

[`ifcb_py_install`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_py_install.md),
[`ifcb_read_features`](https://europeanifcbgroup.github.io/iRfcb/reference/ifcb_read_features.md),
<https://github.com/WHOIGit/ifcb-features>

## Examples

``` r
if (FALSE) { # \dontrun{
# Install the Python environment including ifcb-features
ifcb_py_install(features = TRUE)

# Extract features and blobs from all bins in a data folder
ifcb_extract_features(
  data_folder = "path/to/data",
  features_folder = "path/to/features",
  blobs_folder = "path/to/blobs"
)

# Process a subset of bins in parallel using 4 cores
ifcb_extract_features(
  data_folder = "path/to/data",
  features_folder = "path/to/features",
  blobs_folder = "path/to/blobs",
  bins = c("D20220522T003051_IFCB134", "D20220522T000439_IFCB134"),
  parallel = TRUE,
  n_cores = 4
)

# Write IFCB Dashboard-compatible feature names (<bin>_fea_v4.csv)
ifcb_extract_features(
  data_folder = "path/to/data",
  features_folder = "path/to/features",
  blobs_folder = "path/to/blobs",
  feature_tag = "fea"
)
} # }
```
