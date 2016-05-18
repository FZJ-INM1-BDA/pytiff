import pytiff

DATA_DIR = ""
TILED_GREY = "test_data/small_example_tiled.tif"

def test_open():
    tif = pytiff.Tiff(TILED_GREY)
    assert True
