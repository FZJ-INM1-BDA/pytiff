from hypothesis import HealthCheck
from hypothesis import given, settings
from hypothesis.extra.numpy import arrays
from pytiff import *
import hypothesis.strategies as st
import numpy as np
import pytest
import subprocess
import tifffile
from skimage.data import coffee

def test_write_rgb(tmpdir_factory):
    img = coffee()
    filename = str(tmpdir_factory.mktemp("write").join("rgb_img.tif"))
    with Tiff(filename, "w") as handle:
        handle.write(img, method="tile")
    with Tiff(filename) as handle:
        data = handle[:]
        assert np.all(img == data[:, :, :3])

    with Tiff(filename, "w") as handle:
        handle.write(img, method="scanline")
    with Tiff(filename) as handle:
        data = handle[:]
        assert np.all(img == data[:, :, :3])
