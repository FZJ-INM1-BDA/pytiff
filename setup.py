from setuptools import setup
from distutils.extension import Extension
from Cython.Build import cythonize
from Cython.Distutils import build_ext
import numpy

setup(
    ext_modules = cythonize([
        Extension("pytiff", ["pytiff.pyx"],
        libraries=["tiff"],
        include_dirs=[".", numpy.get_include()],
        language="c++",
        )
    ]),
    cmdclass = {"build_ext": build_ext},
    name="pytiff",
    version="0.2.2"
)
