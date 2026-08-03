"""Backend-tolerant reader for raw IFCB data.

WHOI's ifcb-features package changed its raw-data dependency at release v1.1.0:
releases up to v1.0.0 read data through ``pyifcb`` (imported as ``ifcb``), while
v1.1.0 and later use ``ifcbkit``. The two expose different APIs, so this module
wraps whichever is installed behind one small interface used by
``extract_slim_features``. A single iRfcb installation therefore works against
either ifcb-features version, and both readers may be installed side by side.

The feature computation itself is unaffected: the ``ifcb_features`` code is
unchanged between v1.0.0 and v1.1.1, so the choice of reader does not change how
a region of interest is measured. Both readers use 1-based ROI numbering and
deliver 8-bit grayscale pixel data.

They are *not* equivalent in every case, though:

* Zero-sized ROIs. ``pyifcb`` skips a ROI whose recorded width is zero;
  ``ifcbkit`` skips one whose width *or* height is zero. A ``width > 0,
  height == 0`` row is therefore kept by the former and dropped by the latter.
* Stitching. ``ifcbkit``'s ``read_images`` composites overlapping consecutive
  ROI pairs in older I-style bins and drops the second of the pair from
  iteration; ``pyifcb`` returns both separately. Row counts, ROI numbering and
  feature values consequently differ for I-style data.

For the D-style bins produced by current instruments the two agree and outputs
are interchangeable. For I-style data, pin a reader if results must be
comparable to an earlier run.

``ifcbkit`` is preferred when both are importable, since it is what current
ifcb-features releases depend on and it carries far fewer dependencies. Pass
``backend`` to :func:`open_data_directory` to override that choice, or set the
``IRFCB_IFCB_BACKEND`` environment variable. Note that when this module is
driven from R, the environment variable is read on the R side and forwarded as
``backend``: Python snapshots ``os.environ`` at interpreter start, so a
``Sys.setenv()`` call made after Python has initialised would not be seen here.
"""

import os

#: Environment variable used to force a particular backend.
BACKEND_ENV_VAR = "IRFCB_IFCB_BACKEND"


def _import_ifcbkit():
    import ifcbkit
    return ifcbkit


def _import_pyifcb():
    import ifcb
    return ifcb


class IfcbkitReader:
    """Read raw IFCB data via ``ifcbkit`` (ifcb-features >= 1.1.0)."""

    backend = "ifcbkit"

    def __init__(self, data_directory):
        ifcbkit = _import_ifcbkit()
        # SyncIfcbDataDirectory does not validate its root path, so check here
        # to keep the "missing directory" failure consistent across backends.
        if not os.path.isdir(data_directory):
            raise FileNotFoundError(
                f"data directory not found: {data_directory}")
        self._parse_pid = ifcbkit.parse_pid
        self._dd = ifcbkit.SyncIfcbDataDirectory(data_directory)

    def _lid(self, pid):
        # parse_pid normalises a ROI-suffixed pid down to its bin lid. It raises
        # on unparseable ids; fall back to the raw pid rather than failing the
        # whole listing for one oddly named fileset.
        try:
            return self._parse_pid(pid)['lid']
        except Exception:  # noqa: BLE001 - a bad id must not abort the scan
            return pid

    def list_lids(self):
        return [self._lid(fileset['pid']) for fileset in self._dd.list()]

    def read_images(self, lid):
        # read_images() resolves the fileset itself and raises KeyError for an
        # unknown bin, so no separate existence check is needed - adding one
        # would scan the data directory a second time for every bin.
        return self._dd.read_images(lid)


class PyifcbReader:
    """Read raw IFCB data via ``pyifcb`` (ifcb-features <= 1.0.0)."""

    backend = "pyifcb"

    def __init__(self, data_directory):
        ifcb = _import_pyifcb()
        self._dd = ifcb.DataDirectory(data_directory)

    def list_lids(self):
        return [sample.lid for sample in self._dd]

    def read_images(self, lid):
        # DataDirectory raises KeyError for an unknown bin, matching the
        # ifcbkit reader above.
        return self._dd[lid].images


#: Readers in preference order, as (backend name, import check, class) triples.
_READERS = (
    ("ifcbkit", _import_ifcbkit, IfcbkitReader),
    ("pyifcb", _import_pyifcb, PyifcbReader),
)


def available_backends():
    """Return the names of the raw-data readers that can be imported."""
    names = []
    for name, importer, _ in _READERS:
        try:
            importer()
        except ImportError:
            continue
        names.append(name)
    return names


def open_data_directory(data_directory, backend=None):
    """Open ``data_directory`` with the preferred available reader.

    Args:
        data_directory (str): Path to a directory of raw IFCB data.
        backend (str, optional): Force a specific backend, ``"ifcbkit"`` or
            ``"pyifcb"``. Defaults to the ``IRFCB_IFCB_BACKEND`` environment
            variable, or to the first available reader in preference order.

    Returns:
        IfcbkitReader or PyifcbReader: a reader exposing ``list_lids()`` and
        ``read_images(lid)``.

    Raises:
        ValueError: if a named backend is unknown.
        ImportError: if the requested backend - or, by default, any backend -
            is not installed.
    """
    requested = backend or os.environ.get(BACKEND_ENV_VAR) or None

    if requested is not None:
        known = {name: (importer, cls) for name, importer, cls in _READERS}
        if requested not in known:
            raise ValueError(
                f"Unknown IFCB raw-data backend {requested!r}; "
                f"expected one of {', '.join(known)}.")
        importer, reader_class = known[requested]
        try:
            importer()
        except ImportError as e:
            raise ImportError(
                f"The requested IFCB raw-data backend {requested!r} is not "
                f"installed: {e}") from e
        return reader_class(data_directory)

    for _, importer, reader_class in _READERS:
        try:
            importer()
        except ImportError:
            continue
        return reader_class(data_directory)

    raise ImportError(
        "No IFCB raw-data reader is installed. Install the WHOI ifcb-features "
        "package, which provides one: releases >= 1.1.0 depend on 'ifcbkit', "
        "earlier releases on 'pyifcb'."
    )
