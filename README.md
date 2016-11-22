# pytiff

pytiff is a lightweight library for reading chunks from a tiff file. While it supports other formats to some extend, it is focused on reading tiled greyscale/rgb images, that can also be bigtiffs. Writing tiff files is not supported at all currently. Pytiff supports numpy like slicing and uses numpy arrays to handle image data.

The libtiff library is wrapped using the Cython package.

* develop: [![Build Status](https://travis-ci.org/FZJ-INM1-BDA/pytiff.svg?branch=develop)](https://travis-ci.org/FZJ-INM1-BDA/pytiff)
* master: [![Build Status](https://travis-ci.org/FZJ-INM1-BDA/pytiff.svg?branch=master)](https://travis-ci.org/FZJ-INM1-BDA/pytiff)

## Dependencies

* libtiff C library (>= 4.0 for bigtiff access)
* Cython >= 0.23
* numpy

## Installation

To install pytiff, clone the repo and call setup.py.

```bash
git clone https://github.com/FZJ-INM1-BDA/pytiff.git
cd pytiff
pip install . # or python setup.py install
```

## Development

For development:

```bash
git clone https://github.com/FZJ-INM1-BDA/pytiff.git
cd pytiff
# git checkout development
pip install -e . # or python setup.py develop
```

can be used, so that no reinstallation is needed for every update.
If new updates are pulled the cython part has to be recompiled.
```bash
#compile cython part
python setup.py build_ext --inplace
```

## Usage

A small example how pytiff can be used:

Reading:
```python
import pytiff

with pytiff.Tiff("test_data/small_example_tiled.tif") as handle:
  part = f[100:200, :]
```

Writing data from `pages` into a multipage tiff:
```python
import pytiff
with pytiff.Tiff("test_data/tmp.tif", "w") as handle:
  for p in pages:
    handle.write(p, method="scanline")
```
