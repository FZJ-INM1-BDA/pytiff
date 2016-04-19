from setuptools import setup
from distutils.extension import Extension
from Cython.Build import cythonize
from Cython.Distutils import build_ext

setup(
    ext_modules = cythonize([
        Extension("pytiff", ["pytiff.pyx"],
        libraries=["tiff"],
        include_dirs=["."],
        language="c++"
        )
    ]),
    cmdclass = {"build_ext": build_ext}
)
