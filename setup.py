from setuptools import setup
from distutils.extension import Extension
from Cython.Build import cythonize
from Cython.Distutils import build_ext
import numpy

import pytiff
VERSION = pytiff.__version__
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
    version=VERSION
)
