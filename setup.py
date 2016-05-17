from setuptools import setup
from distutils.extension import Extension
from Cython.Build import cythonize
from Cython.Distutils import build_ext
import numpy

import pytiff._version as _version

setup(
    ext_modules = cythonize([
        Extension("pytiff._pytiff", ["pytiff/_pytiff.pyx"],
        libraries=["tiff"],
        include_dirs=["./pytiff", numpy.get_include()],
        language="c++",
        )
    ]),
    cmdclass = {"build_ext": build_ext},
    name="pytiff",
    version=_version.__version__,
    packages=["pytiff", "pytiff._version"],
    package_dir={
        "pytiff" : "pytiff",
    },
    license="MIT"
)
