=================
Quick start guide
=================

This document talks you through everything you need to get started with pytiff.

----------
Installing
----------

Clone the github repository and install pytiff using setup.py or pip.
Requirements are listed in the requirements.tx:

- numpy
- cython
- libtiff C library > 4.0

.. code:: bash

  git clone https://github.com/FZJ-INM1-BDA/pytiff.git
  cd pytiff
  pip install .

You can also use the -e option with pip for development purposes. Be aware
that you have to rebuild the cython parts if they are changed.

.. code:: bash

  python setup.py build_ext --inplace

-------------------
Reading a tiff file
-------------------

.. code:: python

  import pytiff

  with pytiff.Tiff("test_data/small_example_tiled.tif") as handle:
    part = f[100:200, :]


-------------------
Writing a tiff file
-------------------

.. code:: python

  import pytiff
  with pytiff.Tiff("test_data/tmp.tif", "w") as handle:
    for p in pages:
      handle.write(p, method="scanline")
