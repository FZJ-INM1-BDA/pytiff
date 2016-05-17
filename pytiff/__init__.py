__all__ = ["Tiff", "__version__", "tiff_version", "tiff_version_raw"]
try:
    from ._pytiff import Tiff
    from ._pytiff import __doc__
    from ._pytiff import tiff_version, tiff_version_raw
except ImportError as e:
    print("Cython modules not available")
from pytiff._version import __version__
