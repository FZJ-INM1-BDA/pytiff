import pytiff
import pytest
import tifffile
import numpy as np

TILED_GREY = "test_data/small_example_tiled.tif"
NO_FILE = "test_data/not_here.tif"

def test_open():
    tif = pytiff.Tiff(TILED_GREY)
    assert True

def test_open_fail():
    with pytest.raises(IOError):
        tif = pytiff.Tiff(NO_FILE)

def test_greyscale_tiled():
    with tifffile.TiffFile(TILED_GREY) as tif:
        for page in tif:
            first_page = page.asarray()

    with pytiff.Tiff(TILED_GREY) as tif:
        data = tif[:]
        # test reading whole page
        np.testing.assert_array_equal(first_page, data)
        # test reading a chunk
        chunk = tif[100:200, :]
        np.testing.assert_array_equal(first_page[100:200, :], chunk)

        chunk = tif[:, 250:350]
        np.testing.assert_array_equal(first_page[:, 250:350], chunk)

        chunk = tif[100:200, 250:350]
        np.testing.assert_array_equal(first_page[100:200, 250:350], chunk)


def test_greyscale_not_tiled():
    assert False

def test_rgb_tiled():
    assert False

def test_rgb_not_tiled():
    assert False
