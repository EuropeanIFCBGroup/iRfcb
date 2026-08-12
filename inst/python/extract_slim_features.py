"""Extract slim IFCB features and blobs using WHOI's ifcb-features package.

This module is bundled with the R package 'iRfcb' and is sourced from R via
reticulate (see ifcb_extract_features()). It adapts the upstream
extract_slim_features.py from https://github.com/WHOIGit/ifcb-features so that:

  * features and blobs are written to separate, user-specified directories,
  * existing outputs are skipped unless overwrite is requested,
  * bins can be processed in parallel via a process pool (Linux) or a thread
    pool (when ``use_threads`` is set, e.g. on Windows / macOS where an embedded
    interpreter cannot spawn worker processes),
  * raw data is read through the ``ifcb_reader`` adapter, so either the
    ``ifcbkit`` backend (ifcb-features >= 1.1.0) or the ``pyifcb`` backend
    (ifcb-features <= 1.0.0) can be used; ``backend`` forces one when both are
    installed,
  * a bin that cannot be read is reported as a per-bin error rather than
    aborting the run, so one corrupt file does not discard the results of every
    bin already processed, and
  * complex feature values are reduced to real numbers before being written
    (see ``_real_valued``), keeping the ellipse columns numeric on numpy >= 2.3.

Per-bin outputs are the upstream pair: a ``<lid>_features_v4.csv`` table (30
morphological features per ROI) and a ``<lid>_blobs_v4.zip`` archive of 1-bit
blob masks (one PNG per ROI). Passing ``feature_tag="fea"`` renames the feature
table to ``<lid>_fea_v4.csv``, the name the IFCB Dashboard looks for; the blob
archive name is unaffected. Passing ``multiblob=True`` additionally writes the
``multiblob/<lid>_multiblob_v4.csv`` sidecar upstream introduced in
ifcb-features v1.2.0 (per-blob features for ROIs with more than one blob),
and requires that release or later.

Feature values match upstream. Where ifcb-features returns a complex number -
it does from numpy 2.3 onwards - the real part is taken, which reproduces the
clip-to-zero guard upstream applies to the same degenerate case (see
``_real_valued``), so a given blob measures the same whichever ifcb-features
release is installed.
"""

import argparse
import io
import multiprocessing
import os
import sys
import time
import warnings
import zipfile

import numpy as np
import pandas as pd
from PIL import Image

from ifcb_features.all import compute_features

# Per-blob column names for the multiblob sidecar CSV. Upstream added both the
# list and the multiblob output in ifcb-features v1.2.0, so failing to import
# it identifies an older release (which cannot produce multiblob rows at all).
try:
    from ifcb_features.all import BLOB_FEATURE_COLUMNS
except ImportError:  # ifcb-features < 1.2.0
    BLOB_FEATURE_COLUMNS = None

# Sibling module, imported at module scope so it resolves while this file's
# directory is still on sys.path (reticulate's import_from_path puts it there
# only for the duration of the import).
from ifcb_reader import open_data_directory


def _ensure_module_importable():
    """Add this module's directory to PYTHONPATH if needed.

    On Linux, multiprocessing uses fork and workers inherit sys.path, so
    extract_slim_features is already importable. On Windows and macOS,
    multiprocessing uses spawn: workers start as fresh Python processes and
    only inherit environment variables, not sys.path. Setting PYTHONPATH here
    (before Pool() starts the workers) ensures spawn workers can import this
    module to unpickle _process_bin.
    """
    module_dir = os.path.dirname(os.path.abspath(__file__))
    current = os.environ.get('PYTHONPATH', '')
    parts = [p for p in current.split(os.pathsep) if p]
    if module_dir not in parts:
        os.environ['PYTHONPATH'] = os.pathsep.join([module_dir] + parts)


def _ensure_spawn_executable(python_executable=None):
    """Point multiprocessing at a real Python interpreter for spawn workers.

    Companion to _ensure_module_importable(). On Windows and macOS,
    multiprocessing uses spawn, which relaunches the interpreter named by
    sys.executable to start each worker. When Python is embedded in another
    program - as it is here, running inside R via reticulate - sys.executable
    often points at the host process (e.g. Rterm.exe / the R binary), not a
    usable Python. Spawn workers are then launched as the wrong process, never
    run the bootstrap, and the apply_async results never become ready(): the
    polling loop hangs forever with no error or warning.

    Setting the multiprocessing executable to the actual interpreter fixes this.
    The path is supplied by the R caller via reticulate::py_exe(); if it is not
    given we fall back to sys.executable. Under fork (Linux) nothing is
    relaunched, so this is a no-op there.
    """
    if multiprocessing.get_start_method(allow_none=False) == 'fork':
        return
    exe = python_executable or sys.executable
    if exe and os.path.exists(exe):
        multiprocessing.set_executable(exe)


# ifcb_features/blob_geometry.py hits divide-by-zero when computing the
# orientation of a perfectly axis-aligned blob (x == 0). The result is still
# finite (arctan(y/0) = ±inf → clipped), so the warning is noise.
warnings.filterwarnings("ignore", category=RuntimeWarning,
                        module="ifcb_features")

# Recent scikit-image releases deprecate several functions ifcb_features calls
# (binary_closing / binary_erosion / binary_dilation, equivalent_diameter),
# emitting a FutureWarning per ROI. Nothing in iRfcb can act on these - they
# have to be fixed upstream - and left unfiltered they bury the progress bar.
# Suppressing them does not hide an eventual removal, which surfaces as an
# ImportError or AttributeError instead.
# Upstream removed these deprecated calls in ifcb-features PR #16, merged to
# main 2026-07-23 but not yet released (the latest release, v1.1.1, still emits
# the warnings). The filters are harmless on fixed versions (no such warning is
# raised), so they stay for v1.1.1 compatibility.
warnings.filterwarnings("ignore", category=FutureWarning,
                        module="ifcb_features")

# A second filter is needed because module= matches the module a warning is
# attributed to, not the one that started the call chain. The filter above
# covers the functions ifcb_features calls itself. It cannot cover scikit-image
# calling its own deprecated functions internally (morphology/binary.py:
# binary_closing -> binary_erosion), which is attributed to
# skimage.morphology.binary. scikit-image guards that inner call with
# warnings.catch_warnings(), but that swaps the global filter list and is not
# thread-safe: on the thread pool used when Python is embedded on Windows and
# macOS, a worker leaving the block restores a snapshot taken before another
# worker entered, and the warning escapes. Installing a filter here at import
# time avoids the race and reaches every pool backend (fork inherits the
# filters, spawn re-imports this module, threads share the interpreter).
# Matching the message as well as the module keeps this limited to the
# morphology deprecations, so any other scikit-image FutureWarning is still
# shown. The backticks are scikit-image's: its deprecation decorator wraps the
# function name in them, and the pattern is anchored at the start.
warnings.filterwarnings("ignore", category=FutureWarning,
                        message="`binary_(closing|opening|erosion|dilation)` is deprecated",
                        module="skimage")

# The "slim" feature columns produced by ifcb_features.all.compute_features,
# in the same order as upstream extract_slim_features.py.
FEATURE_COLUMNS = [
    'Area',
    'Biovolume',
    'BoundingBox_xwidth',
    'BoundingBox_ywidth',
    'ConvexArea',
    'ConvexPerimeter',
    'Eccentricity',
    'EquivDiameter',
    'Extent',
    'MajorAxisLength',
    'MinorAxisLength',
    'Orientation',
    'Perimeter',
    'RepresentativeWidth',
    'Solidity',
    'SurfaceArea',
    'maxFeretDiameter',
    'minFeretDiameter',
    'numBlobs',
    'summedArea',
    'summedBiovolume',
    'summedConvexArea',
    'summedConvexPerimeter',
    'summedMajorAxisLength',
    'summedMinorAxisLength',
    'summedPerimeter',
    'summedSurfaceArea',
    'Area_over_PerimeterSquared',
    'Area_over_Perimeter',
    'summedConvexPerimeter_over_Perimeter',
]


def _real_valued(roi_features):
    """Reduce complex feature values to the real numbers upstream reports.

    ``ifcb_features`` derives the ellipse properties (Eccentricity,
    MajorAxisLength, MinorAxisLength) from ``numpy.linalg.eig``. For a real
    symmetric covariance matrix that used to yield real eigenvalues, but from
    numpy 2.3 onwards eig returns complex ones, so those three features arrive
    as complex numbers. Written straight to CSV they become "(0.797+0j)"
    strings, silently turning numeric columns into text. They are the only
    complex columns: Orientation comes from a separate ``explicit_orientation``
    routine, and the ``summed*`` variants are already real (see below).

    Taking the real part matches upstream in both cases that arise, since
    ``ellipse_properties`` computes ``L = 4 * sqrt(eVal)``. A non-negative
    eigenvalue gives a real root with a zero imaginary part, so the real part is
    the value itself. A degenerate (collinear) blob can make ``np.cov`` return a
    slightly negative eigenvalue, and ``sqrt(-x)`` is ``0 + i*sqrt(x)`` on the
    principal branch, whose real part is 0.0. That is the value upstream gets by
    clipping the radicand: ``real(sqrt(z)) == sqrt(clip(z, 0, None))`` holds for
    every real ``z``, so the two agree by construction. ``ifcb_features``
    already relies on this itself, casting the same complex value to float in
    ``summed_attr``, so summedMajorAxisLength and summedMinorAxisLength report
    such a blob as 0 on numpy >= 2.3.

    On numpy < 2.3 this is a no-op (``np.iscomplexobj`` is False). eig returns
    real eigenvalues there, the root of a negative one is NaN, and since np.max
    and np.min propagate NaN, one degenerate blob makes all three columns NaN.
    That older behaviour passes through untouched, which is what reproducing an
    ifcb-features v1.0.0 run depends on.

    Upstream made the clip explicit in ifcb-features PR #20 (switching to
    numpy.linalg.eigh), merged to main 2026-07-23 but not yet in a tagged
    release; v1.1.1 still returns complex values.

    Args:
        roi_features: iterable of (name, value) pairs from compute_features.

    Returns:
        list: the same pairs with complex values reduced to floats.
    """
    out = []
    for name, value in roi_features:
        if np.iscomplexobj(value):
            value = float(np.real(value))
        out.append((name, value))
    return out


def _unpack_compute_features(result):
    """Normalise a compute_features result to (blobs_image, features, multiblob).

    ifcb-features v1.2.0 changed compute_features to return a 3-tuple
    ``(blobs_image, features, multiblob_rows)``; v1.1.x and earlier return
    ``(blobs_image, features)``. A direct 2-tuple unpack raises ValueError on
    v1.2.0 for every ROI, which the per-ROI error handling would swallow into
    feature rows containing only roi_number. Both shapes are accepted here;
    on older releases, which never compute per-blob rows, the multiblob
    element is an empty list.
    """
    multiblob_rows = result[2] if len(result) > 2 else []
    return result[0], result[1], multiblob_rows


def _output_paths(lid, features_directory, blobs_directory,
                  feature_tag="features"):
    """Return the (features_csv, blobs_zip) output paths for a bin lid.

    ``feature_tag`` controls the token between the bin lid and the version in
    the feature CSV name: ``"features"`` (default) yields the upstream
    ``<lid>_features_v4.csv``; ``"fea"`` yields ``<lid>_fea_v4.csv``, which is
    the name the IFCB Dashboard (pyifcb's FeaturesDirectory) looks for. The
    blob archive name is unaffected.
    """
    features_path = os.path.join(features_directory,
                                 f"{lid}_{feature_tag}_v4.csv")
    blobs_path = os.path.join(blobs_directory, f"{lid}_blobs_v4.zip")
    return features_path, blobs_path


def _multiblob_path(lid, features_directory):
    """Return the multiblob sidecar CSV path for a bin lid.

    Upstream extract_slim_features.py writes these into a ``multiblob``
    subdirectory of its output directory; iRfcb keeps that layout under the
    features directory. The name is fixed (no ``feature_tag`` token): upstream
    defines it, and the IFCB Dashboard has no alternative naming for it.
    """
    return os.path.join(features_directory, "multiblob",
                        f"{lid}_multiblob_v4.csv")


def _expects_multiblob(features_path):
    """Whether an existing feature CSV reports any multi-blob ROI.

    Reads only the numBlobs column, so the check stays cheap enough to run
    per bin while deciding whether to skip it. Returns True or False, or None
    when the file cannot be read or carries no numBlobs column; callers treat
    None as "unknown, recompute". A ROI whose extraction failed has an empty
    numBlobs cell, which compares as not-greater-than-1 here and is fine
    either way: such a bin has no trustworthy sidecar expectation, but
    re-extracting it would fail the same ROI again.
    """
    try:
        num_blobs = pd.read_csv(features_path, usecols=["numBlobs"])["numBlobs"]
        return bool((num_blobs > 1).any())
    except Exception:  # noqa: BLE001 - unreadable/legacy CSV means "unknown"
        return None


def _require_multiblob_support():
    """Raise when the installed ifcb-features cannot produce multiblob rows."""
    if BLOB_FEATURE_COLUMNS is None:
        raise ValueError(
            "multiblob output requires ifcb-features >= 1.2.0; the installed "
            "release does not provide it. Reinstall the latest release with "
            "ifcb_py_install(features = TRUE).")


def _process_bin(data_directory, features_directory, blobs_directory, bin_name,
                 overwrite, feature_tag="features", backend=None,
                 multiblob=False):
    """Extract features and blobs for a single bin.

    This is a module-level function so it can be pickled and dispatched to a
    pool worker (a process under ``multiprocessing.Pool``, or a thread under
    ``ThreadPool``). Each call opens its own reader because the underlying
    bin objects are not picklable and to avoid sharing state between workers.

    ``feature_tag`` is forwarded to :func:`_output_paths` to control the
    feature CSV name (e.g. ``"features"`` or ``"fea"``). ``backend`` forces a
    particular raw-data reader; see :func:`ifcb_reader.open_data_directory`.
    ``multiblob`` additionally writes a ``multiblob/<lid>_multiblob_v4.csv``
    sidecar with per-blob features for ROIs holding more than one blob; as
    upstream, a bin without such ROIs gets no sidecar at all. Requires
    ifcb-features >= 1.2.0.

    Returns a dict with keys ``bin``, ``status`` ("processed", "skipped" or
    "error") and ``message``.
    """
    if multiblob and BLOB_FEATURE_COLUMNS is None:
        return {"bin": bin_name, "status": "error",
                "message": "multiblob output requires ifcb-features >= 1.2.0"}

    features_path, blobs_path = _output_paths(bin_name, features_directory,
                                              blobs_directory, feature_tag)
    mb_path = _multiblob_path(bin_name, features_directory) if multiblob else None
    output_paths = [features_path, blobs_path] + ([mb_path] if multiblob else [])

    # Skip when the outputs already exist (unless overwrite is requested).
    # The multiblob sidecar follows upstream in existing only for bins that
    # hold at least one multi-blob ROI, so its absence alone does not mean the
    # bin needs re-extracting: the numBlobs column of the existing feature CSV
    # says whether a sidecar is expected at all. A multiblob re-run over a
    # directory extracted without it therefore recomputes only the bins whose
    # sidecar is genuinely missing.
    if not overwrite and os.path.exists(features_path) and os.path.exists(blobs_path):
        if not multiblob or os.path.exists(mb_path):
            return {"bin": bin_name, "status": "skipped",
                    "message": "outputs already exist"}
        if _expects_multiblob(features_path) is False:
            return {"bin": bin_name, "status": "skipped",
                    "message": "outputs already exist (no multi-blob ROIs)"}
        # The sidecar is missing but expected - or the feature CSV could not
        # be read, leaving the expectation unknown - so re-extract the bin.

    # Resolving the bin and iterating its images fail in different ways and are
    # kept apart so each can be reported accurately: only an unresolvable bin is
    # "not found".
    try:
        reader = open_data_directory(data_directory, backend=backend)
        images = reader.read_images(bin_name)
    except KeyError:
        return {"bin": bin_name, "status": "error",
                "message": "bin not found in data directory"}
    except Exception as e:  # noqa: BLE001 - report any access failure to R
        return {"bin": bin_name, "status": "error", "message": str(e)}

    try:
        # pyifcb's Mapping yields images lazily, so a corrupt or truncated .roi
        # raises from the *iteration*, not from read_images(). Materialising the
        # pairs here keeps that failure inside a try block; otherwise it escapes
        # as an unhandled traceback and, in sequential mode, discards the
        # results of every bin already processed.
        image_items = list(images.items())
    except Exception as e:  # noqa: BLE001 - a bad bin must not abort the run
        return {"bin": bin_name, "status": "error", "message": str(e)}

    all_features = []
    all_blobs = {}
    all_multiblob = []

    for number, image in image_items:
        features = {'roi_number': number}
        try:
            blobs_image, roi_features, multiblob_rows = _unpack_compute_features(
                compute_features(image))
            features.update(_real_valued(roi_features))

            img_buffer = io.BytesIO()
            Image.fromarray((blobs_image > 0).astype(np.uint8) * 255).save(
                img_buffer, format="PNG")
            all_blobs[number] = img_buffer.getvalue()

            if multiblob:
                for blob_number, blob_feats in multiblob_rows:
                    row = {'roi_number': number, 'blob_number': blob_number}
                    row.update(dict(_real_valued(blob_feats.items())))
                    all_multiblob.append(row)
        except Exception as e:  # noqa: BLE001 - skip a bad ROI, keep the rest
            print(f"Error processing ROI {number} in sample {bin_name}: {e}")

        all_features.append(features)

    if not all_features:
        return {"bin": bin_name, "status": "error",
                "message": "no ROIs found in bin"}

    # Writing the outputs can fail like anything else (read-only or full
    # volume, quota, MemoryError on a large bin). The parallel path already
    # contains worker exceptions; without this guard the same failure in
    # sequential mode escapes extract_features() and discards the results of
    # every bin already processed.
    try:
        df = pd.DataFrame.from_records(all_features,
                                       columns=['roi_number'] + FEATURE_COLUMNS)
        df.to_csv(features_path, index=False, float_format="%.10g")

        if all_blobs:
            with zipfile.ZipFile(blobs_path, 'w') as zf:
                for roi_number, blob_data in all_blobs.items():
                    filename = f"{bin_name}_{roi_number:05d}.png"
                    zf.writestr(filename, blob_data)

        if multiblob:
            if all_multiblob:
                os.makedirs(os.path.dirname(mb_path), exist_ok=True)
                mb_df = pd.DataFrame.from_records(
                    all_multiblob,
                    columns=['roi_number', 'blob_number'] + BLOB_FEATURE_COLUMNS)
                mb_df.to_csv(mb_path, index=False, float_format="%.10g")
            elif os.path.exists(mb_path):
                # No multi-blob ROIs this run: as upstream, no file is
                # written; also drop a stale sidecar left by an earlier run,
                # which would otherwise contradict the fresh feature CSV.
                os.remove(mb_path)
    except Exception as e:  # noqa: BLE001 - a failed write must not abort the run
        # Drop any partial output so a rerun does not skip this bin.
        for path in output_paths:
            try:
                if os.path.exists(path):
                    os.remove(path)
            except OSError:
                pass
        return {"bin": bin_name, "status": "error", "message": str(e)}

    return {"bin": bin_name, "status": "processed", "message": ""}


def _resolve_bins(data_directory, bins, backend=None):
    """Return the list of bin lids to process.

    When ``bins`` is None, every bin in the data directory is returned.
    Otherwise the requested bins are filtered against the directory and any
    missing ones are reported back to the caller. ``backend`` forces a
    particular raw-data reader.
    """
    reader = open_data_directory(data_directory, backend=backend)
    lids = reader.list_lids()

    if not bins:
        return lids, []

    available = set(lids)
    requested = [str(b) for b in bins]
    found = [b for b in requested if b in available]
    missing = [b for b in requested if b not in available]
    return found, missing


def list_bins(data_directory, bins=None, backend=None):
    """Return the bins that would be processed for the given inputs.

    Args:
        data_directory (str): Path to the raw IFCB data directory.
        bins (list, optional): Bin lids to restrict to. If None, all bins are
            listed.
        backend (str, optional): Force a specific raw-data reader, ``"ifcbkit"``
            or ``"pyifcb"``.

    Returns:
        dict: ``{"found": [...], "missing": [...]}`` where ``found`` are the bin
        lids present in the data directory and ``missing`` are any requested bins
        that were not found.
    """
    found, missing = _resolve_bins(data_directory, bins, backend=backend)
    return {"found": found, "missing": missing}


class ParallelExtractor:
    """Process IFCB bins across pool workers, polled incrementally.

    Bins are submitted to a pool up front; completed results are retrieved
    non-blockingly via :meth:`poll`. This design lets the *caller* (the R
    wrapper) drive the loop and check for interrupts between polls, and lets the
    workers be stopped via :meth:`terminate`.

    The pool is a ``multiprocessing.Pool`` (separate worker processes, true
    multi-core parallelism) by default, or a ``multiprocessing.pool.ThreadPool``
    (worker threads in this interpreter) when ``use_threads`` is set. Threads are
    the reliable choice when Python is embedded in another program (e.g. R via
    reticulate) on Windows / macOS, where spawning worker processes from an
    embedded interpreter hangs.

    Stopping behaviour differs between the two:

      * Process pool: workers are daemonic, so :meth:`terminate` kills them
        immediately and they are also reaped if the parent process exits. An
        interrupted run leaves no workers writing files in the background.
      * Thread pool: a thread cannot be force-killed, so a bin already running
        inside ``compute_features`` finishes (and writes its outputs) even after
        :meth:`terminate`. The pool stops dispatching *new* bins promptly.

    Note also that under a thread pool the GIL limits speedup to the parts of
    the work that release it (most of the numpy / scikit-image computation does).
    """

    def __init__(self, data_directory, features_directory, blobs_directory,
                 bins=None, overwrite=False, num_workers=2,
                 found_bins=None, missing_bins=None, python_executable=None,
                 use_threads=False, feature_tag="features", backend=None,
                 multiblob=False):
        if multiblob:
            _require_multiblob_support()
        os.makedirs(features_directory, exist_ok=True)
        os.makedirs(blobs_directory, exist_ok=True)

        if found_bins is not None:
            # Accept a pre-resolved bin list to avoid a second DataDirectory
            # scan (the caller already paid for one in list_bins()).
            # Guard against a bare string (reticulate converts a length-1 R
            # character vector to a Python str, not a list).
            if isinstance(found_bins, str):
                found_bins = [found_bins]
            if isinstance(missing_bins, str):
                missing_bins = [missing_bins]
            bin_names = [str(b) for b in found_bins]
            self.missing = [str(b) for b in (missing_bins or [])]
        else:
            bin_names, self.missing = _resolve_bins(data_directory, bins,
                                                    backend=backend)
        self.total = len(bin_names)

        if use_threads:
            # Thread-based pool: workers are threads in this interpreter, so
            # there is no spawn, no pickling and no child-process bootstrap.
            # This is the reliable choice when Python is embedded (reticulate)
            # on Windows / macOS, where process spawn from an embedded
            # interpreter hangs. compute_features spends most of its time in
            # scikit-image / numpy, which release the GIL, so threads still
            # parallelise the heavy work.
            from multiprocessing.pool import ThreadPool
            self.pool = ThreadPool(processes=max(1, int(num_workers)))
        else:
            # Process-based pool: true multi-core parallelism. Safe under fork
            # (Linux). Avoid on Windows / macOS when embedded in R.
            _ensure_module_importable()
            _ensure_spawn_executable(python_executable)
            self.pool = multiprocessing.Pool(processes=max(1, int(num_workers)))
        self._pending = [
            (bin_name, self.pool.apply_async(
                _process_bin,
                (data_directory, features_directory, blobs_directory,
                 bin_name, overwrite, feature_tag, backend, multiblob)))
            for bin_name in bin_names
        ]

    def poll(self):
        """Return a list of result dicts for bins that have finished since the
        last call (non-blocking)."""
        done = []
        still_pending = []
        for bin_name, async_result in self._pending:
            if async_result.ready():
                try:
                    done.append(async_result.get())
                except Exception as e:  # noqa: BLE001 - surface worker crash
                    done.append({"bin": bin_name, "status": "error",
                                 "message": str(e)})
            else:
                still_pending.append((bin_name, async_result))
        self._pending = still_pending
        return done

    def remaining(self):
        """Number of bins not yet collected."""
        return len(self._pending)

    def terminate(self):
        """Stop the pool immediately, discarding pending work.

        For a process pool this kills the worker processes; for a thread pool it
        stops dispatching new bins (a bin already in flight runs to completion,
        see the class docstring).
        """
        try:
            self.pool.terminate()
            self.pool.join()
        except Exception:  # noqa: BLE001 - terminate must never raise
            pass


def extract_features(data_directory, features_directory, blobs_directory,
                     bins=None, overwrite=False, num_workers=1, progress=None,
                     python_executable=None, use_threads=False,
                     feature_tag="features", backend=None, multiblob=False):
    """Extract slim features and blobs for IFCB bins.

    Args:
        data_directory (str): Path to the raw IFCB data directory (searched
            recursively by the raw-data reader; see ifcb_reader).
        features_directory (str): Directory where ``*_features_v4.csv`` files
            are written. Created if it does not exist.
        blobs_directory (str): Directory where ``*_blobs_v4.zip`` files are
            written. Created if it does not exist.
        bins (list, optional): Bin lids (e.g. 'D20240423T115846_IFCB127') to
            process. If None, all bins in ``data_directory`` are processed.
        overwrite (bool): If False (default), bins whose feature CSV and blob
            ZIP both already exist are skipped.
        num_workers (int): Number of pool workers. 1 (default) runs
            sequentially; values > 1 use a pool (worker processes, or threads
            when ``use_threads`` is True).
        progress (callable, optional): Called as ``progress(done, total)`` after
            each bin completes, where ``done`` is the number of bins finished and
            ``total`` is the number to process. Used to drive a progress bar.
        python_executable (str, optional): Path to the real Python interpreter,
            used to point a spawn-based process pool at a usable interpreter when
            this module is run from an embedded interpreter (reticulate). Ignored
            under fork and when ``use_threads`` is True. Typically supplied from
            R via ``reticulate::py_exe()``.
        use_threads (bool): If True, use a thread pool instead of a process pool
            (see ParallelExtractor). Required when running embedded on
            Windows / macOS; on Linux a process pool is preferred.
        feature_tag (str): Token placed between the bin lid and the version in
            the feature CSV name. ``"features"`` (default) writes
            ``<lid>_features_v4.csv``; ``"fea"`` writes ``<lid>_fea_v4.csv``,
            the name served by the IFCB Dashboard. Blob archive names are
            unaffected.
        backend (str, optional): Force a specific raw-data reader, ``"ifcbkit"``
            or ``"pyifcb"``. If None, the preferred available reader is used.
        multiblob (bool): If True, additionally write a
            ``multiblob/<lid>_multiblob_v4.csv`` sidecar under
            ``features_directory`` holding per-blob features for ROIs with more
            than one blob; bins without such ROIs get no sidecar (upstream
            behaviour). Requires ifcb-features >= 1.2.0 (raises ValueError
            on older releases).

    Returns:
        list[dict]: One result dict per bin with keys ``bin``, ``status`` and
        ``message``. Missing requested bins are reported with status "error".
    """
    if multiblob:
        _require_multiblob_support()

    os.makedirs(features_directory, exist_ok=True)
    os.makedirs(blobs_directory, exist_ok=True)

    bin_names, missing = _resolve_bins(data_directory, bins, backend=backend)

    results = [{"bin": b, "status": "error",
                "message": "bin not found in data directory"}
               for b in missing]

    total = len(bin_names)
    done = [0]

    def _report():
        done[0] += 1
        if progress is not None:
            progress(done[0], total)

    num_workers = max(1, int(num_workers))

    if num_workers <= 1 or len(bin_names) <= 1:
        for bin_name in bin_names:
            results.append(_process_bin(data_directory, features_directory,
                                        blobs_directory, bin_name, overwrite,
                                        feature_tag, backend, multiblob))
            _report()
    else:
        # Delegate to ParallelExtractor and poll it to completion. On any
        # exception (including KeyboardInterrupt) the workers are terminated so
        # they stop immediately and do not keep writing files.
        extractor = ParallelExtractor(data_directory, features_directory,
                                      blobs_directory, bins, overwrite,
                                      num_workers,
                                      python_executable=python_executable,
                                      use_threads=use_threads,
                                      feature_tag=feature_tag,
                                      backend=backend,
                                      multiblob=multiblob)
        try:
            while extractor.remaining() > 0:
                for result in extractor.poll():
                    results.append(result)
                    _report()
                if extractor.remaining() > 0:
                    time.sleep(0.05)
        except BaseException:
            extractor.terminate()
            raise
        else:
            extractor.terminate()

    return results


def _main(argv=None):
    """Command-line entry point for standalone use.

    Not used when the module is sourced from R via reticulate (which executes
    the file with ``__name__ == "__main__"``); call this explicitly instead,
    e.g. ``python -c "import extract_slim_features as e; e._main()"``.
    """
    parser = argparse.ArgumentParser(
        description="Extract slim ROI features and blobs from IFCB data.")
    parser.add_argument("data_directory",
                        help="Path to the directory containing IFCB data.")
    parser.add_argument("features_directory",
                        help="Directory to save *_features_v4.csv files.")
    parser.add_argument("blobs_directory",
                        help="Directory to save *_blobs_v4.zip files.")
    parser.add_argument("--bins", nargs='+',
                        help="Bin lids to process (space-separated). Default: all.")
    parser.add_argument("--overwrite", action="store_true",
                        help="Overwrite existing outputs instead of skipping.")
    parser.add_argument("--workers", type=int, default=1,
                        help="Number of worker processes (default: 1).")
    parser.add_argument("--feature-tag", default="features",
                        choices=["features", "fea"],
                        help="Token in the feature CSV name: 'features' -> "
                             "<lid>_features_v4.csv (default), 'fea' -> "
                             "<lid>_fea_v4.csv (IFCB Dashboard naming).")
    parser.add_argument("--multiblob", action="store_true",
                        help="Also write multiblob/<lid>_multiblob_v4.csv "
                             "sidecars (per-blob features for multi-blob ROIs;"
                             " requires ifcb-features >= 1.2.0).")

    args = parser.parse_args(argv)

    beginning = time.time()
    out = extract_features(args.data_directory, args.features_directory,
                           args.blobs_directory, args.bins, args.overwrite,
                           args.workers, feature_tag=args.feature_tag,
                           multiblob=args.multiblob)
    elapsed = time.time() - beginning

    processed = sum(1 for r in out if r["status"] == "processed")
    skipped = sum(1 for r in out if r["status"] == "skipped")
    errored = sum(1 for r in out if r["status"] == "error")
    print(f"Processed: {processed}, skipped: {skipped}, errors: {errored}")
    print(f"Total extract time: {elapsed:.2f} seconds")
