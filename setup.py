from setuptools import setup
from distutils.extension import Extension
from Cython.Build import cythonize
from Cython.Distutils import build_ext
import numpy
import sys
import pytiff._version as _version

directives = {}
macros = []

if "--cov" in sys.argv:
    directives = {"linetrace": True}
    macros = [("CYTHON_TRACE", "1")]
    sys.argv.remove("--cov")


setup(
    ext_modules = cythonize([
        Extension("pytiff._pytiff", ["pytiff/_pytiff.pyx"],
        libraries=["tiff"],
        include_dirs=["./pytiff", numpy.get_include()],
        language="c++",
        define_macros=macros,
        )
    ],
    compiler_directives=directives),
    cmdclass = {"build_ext": build_ext},
    name="pytiff",
    version=_version.__version__,
    packages=["pytiff", "pytiff._version"],
    package_dir={
        "pytiff" : "pytiff",
    },
    license="BSD"
)
