# pytiff

pytiff is a lightweight library for reading chunks from a tiff file. While it supports other formats to some extend, it is focused on reading tiled greyscale/rgb images, that can also be bigtiffs. Writing tiff files is not supported at all currently. Pytiff supports numpy like slicing and uses numpy arrays to handle image data.

The libtiff library is wrapped using the Cython package.

## Dependencies

* libtiff C library (>= 4.0 for bigtiff access)
* Cython >= 0.23
* numpy

## Installation

To install pytiff, call:

`python setup.py install`

## Usage

A small example how pytiff can be used:

```python
import pytiff

with pytiff.Tiff("test_data/small_example_tiled.tif") as f:
  part = f[100:200, :]
```

## Development

For development:

`python setup.py develop`

can be used, so that no reinstallation is needed for every update.
