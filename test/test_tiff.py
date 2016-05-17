import pytiff

TILED_GREY = "test_data/small_example_tiled.tif"

def test_open():
    from pytiff import _version
    print(_version.__file__)
    tif = pytiff.Tiff(TILED_GREY)
    assert True
