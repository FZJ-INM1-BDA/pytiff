from setuptools import setup
from distutils.extension import Extension
import pip
try:
    from Cython.Build import cythonize
    from Cython.Distutils import build_ext
except:
    print("Installing Cython because it is needed in setup.py")
    pip.main(["install", "cython"])
    from Cython.Build import cythonize
    from Cython.Distutils import build_ext

try:
    import numpy
except:
    print("Installing numpy because it is needed in setup.py")
    pip.main(["install", "numpy"])
    import numpy
import sys
import os
import pytiff._version as _version

directives = {}
macros = []

if "--cov" in sys.argv:
    print("Compiling with Coverage on")
    directives = {"linetrace": True}
    macros = [("CYTHON_TRACE", "1")]
    print(directives)
    print(macros)
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
