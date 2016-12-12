__all__ = ["Tiff", "byteorder", "is_bigtiff", "__version__", "tiff_version", "tiff_version_raw"]

from .utils import byteorder, is_bigtiff
try:
    from ._pytiff import Tiff
    from ._pytiff import __doc__
    from ._pytiff import tiff_version, tiff_version_raw
except ImportError as e:
    print("Cython modules not available")
from pytiff._version import __version__
