__all__ = ["Tiff", "__version__"]
try:
    from ._pytiff import Tiff
    from ._pytiff import __doc__
    from ._pytiff import tiff_version, tiff_version_raw
except ImportError as e:
    print("Cython modules not available")
__version__ = "0.3.1"
