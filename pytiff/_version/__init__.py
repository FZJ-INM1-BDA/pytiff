"""
_version
Version information for pytiff.
"""

__all__ = [
    'VERSION_MAJOR',
    'VERSION_MINOR',
    'VERSION_PATCH',
    'VERSION_STRING',
    '__version__',
]

VERSION_MAJOR = 0
VERSION_MINOR = 3
VERSION_PATCH = 4

VERSION_STRING = "{major}.{minor}.{patch}".format(major=VERSION_MAJOR, minor=VERSION_MINOR, patch=VERSION_PATCH)

__version__ = VERSION_STRING
