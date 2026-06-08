"""Extract slim IFCB features and blobs using WHOI's ifcb-features package.

This module is bundled with the R package 'iRfcb' and is sourced from R via
reticulate (see ifcb_extract_features()). It adapts the upstream
extract_slim_features.py from https://github.com/WHOIGit/ifcb-features so that:

  * features and blobs are written to separate, user-specified directories,
  * existing outputs are skipped unless overwrite is requested, and
  * bins can be processed in parallel via a process pool (Linux) or a thread
    pool (when ``use_threads`` is set, e.g. on Windows / macOS where an embedded
    interpreter cannot spawn worker processes).

It still produces the same per-bin outputs as upstream: a
``<lid>_features_v4.csv`` table (30 morphological features per ROI) and a
``<lid>_blobs_v4.zip`` archive of 1-bit blob masks (one PNG per ROI).
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

from ifcb import DataDirectory
from ifcb_features.all import compute_features


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


def _output_paths(lid, features_directory, blobs_directory):
    """Return the (features_csv, blobs_zip) output paths for a bin lid."""
    features_path = os.path.join(features_directory, f"{lid}_features_v4.csv")
    blobs_path = os.path.join(blobs_directory, f"{lid}_blobs_v4.zip")
    return features_path, blobs_path


def _process_bin(data_directory, features_directory, blobs_directory, bin_name,
                 overwrite):
    """Extract features and blobs for a single bin.

    This is a module-level function so it can be pickled and dispatched to a
    pool worker (a process under ``multiprocessing.Pool``, or a thread under
    ``ThreadPool``). Each call rebuilds its own ``DataDirectory`` because the
    pyifcb sample objects are not picklable and to avoid sharing state between
    workers.

    Returns a dict with keys ``bin``, ``status`` ("processed", "skipped" or
    "error") and ``message``.
    """
    features_path, blobs_path = _output_paths(bin_name, features_directory,
                                              blobs_directory)

    # Skip when both outputs already exist (unless overwrite is requested).
    if not overwrite and os.path.exists(features_path) and os.path.exists(blobs_path):
        return {"bin": bin_name, "status": "skipped",
                "message": "outputs already exist"}

    try:
        data_dir = DataDirectory(data_directory)
        sample = data_dir[bin_name]
    except KeyError:
        return {"bin": bin_name, "status": "error",
                "message": "bin not found in data directory"}
    except Exception as e:  # noqa: BLE001 - report any access failure to R
        return {"bin": bin_name, "status": "error", "message": str(e)}

    all_features = []
    all_blobs = {}

    for number, image in sample.images.items():
        features = {'roi_number': number}
        try:
            blobs_image, roi_features = compute_features(image)
            features.update(roi_features)

            img_buffer = io.BytesIO()
            Image.fromarray((blobs_image > 0).astype(np.uint8) * 255).save(
                img_buffer, format="PNG")
            all_blobs[number] = img_buffer.getvalue()
        except Exception as e:  # noqa: BLE001 - skip a bad ROI, keep the rest
            print(f"Error processing ROI {number} in sample {sample.pid}: {e}")

        all_features.append(features)

    if not all_features:
        return {"bin": bin_name, "status": "error",
                "message": "no ROIs found in bin"}

    df = pd.DataFrame.from_records(all_features,
                                   columns=['roi_number'] + FEATURE_COLUMNS)
    df.to_csv(features_path, index=False, float_format="%.10g")

    if all_blobs:
        with zipfile.ZipFile(blobs_path, 'w') as zf:
            for roi_number, blob_data in all_blobs.items():
                filename = f"{bin_name}_{roi_number:05d}.png"
                zf.writestr(filename, blob_data)

    return {"bin": bin_name, "status": "processed", "message": ""}


def _resolve_bins(data_directory, bins):
    """Return the list of bin lids to process.

    When ``bins`` is None, every bin in the data directory is returned.
    Otherwise the requested bins are filtered against the directory and any
    missing ones are reported back to the caller.
    """
    data_dir = DataDirectory(data_directory)

    if not bins:
        return [sample.lid for sample in data_dir], []

    available = {sample.lid for sample in data_dir}
    requested = [str(b) for b in bins]
    found = [b for b in requested if b in available]
    missing = [b for b in requested if b not in available]
    return found, missing


def list_bins(data_directory, bins=None):
    """Return the bins that would be processed for the given inputs.

    Args:
        data_directory (str): Path to the raw IFCB data directory.
        bins (list, optional): Bin lids to restrict to. If None, all bins are
            listed.

    Returns:
        dict: ``{"found": [...], "missing": [...]}`` where ``found`` are the bin
        lids present in the data directory and ``missing`` are any requested bins
        that were not found.
    """
    found, missing = _resolve_bins(data_directory, bins)
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
                 use_threads=False):
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
            bin_names, self.missing = _resolve_bins(data_directory, bins)
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
                 bin_name, overwrite)))
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
                     python_executable=None, use_threads=False):
    """Extract slim features and blobs for IFCB bins.

    Args:
        data_directory (str): Path to the raw IFCB data directory (searched
            recursively by pyifcb's DataDirectory).
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

    Returns:
        list[dict]: One result dict per bin with keys ``bin``, ``status`` and
        ``message``. Missing requested bins are reported with status "error".
    """
    os.makedirs(features_directory, exist_ok=True)
    os.makedirs(blobs_directory, exist_ok=True)

    bin_names, missing = _resolve_bins(data_directory, bins)

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
                                        blobs_directory, bin_name, overwrite))
            _report()
    else:
        # Delegate to ParallelExtractor and poll it to completion. On any
        # exception (including KeyboardInterrupt) the workers are terminated so
        # they stop immediately and do not keep writing files.
        extractor = ParallelExtractor(data_directory, features_directory,
                                      blobs_directory, bins, overwrite,
                                      num_workers,
                                      python_executable=python_executable,
                                      use_threads=use_threads)
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

    args = parser.parse_args(argv)

    beginning = time.time()
    out = extract_features(args.data_directory, args.features_directory,
                           args.blobs_directory, args.bins, args.overwrite,
                           args.workers)
    elapsed = time.time() - beginning

    processed = sum(1 for r in out if r["status"] == "processed")
    skipped = sum(1 for r in out if r["status"] == "skipped")
    errored = sum(1 for r in out if r["status"] == "error")
    print(f"Processed: {processed}, skipped: {skipped}, errors: {errored}")
    print(f"Total extract time: {elapsed:.2f} seconds")
