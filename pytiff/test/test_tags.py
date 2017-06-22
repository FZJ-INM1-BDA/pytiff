from hypothesis import given, settings
import hypothesis.strategies as st
from pytiff import *
import tifffile
import numpy as np
import sys
import logging

def test_tags():
    with Tiff("test_data/small_example_tiled.tif") as handle:
        tags = handle.read_tags()

    with tifffile.TiffFile("test_data/small_example_tiled.tif") as handle:
        page1 = handle.pages[0]
        for tag in page1.tags.values():
            name, value = tag.name, tag.value
            if isinstance(value, bytes):
                value = value.decode()
                assert value == tags[name], "key {}: {} == {}".format(name, value, tags[name])
            elif name == "x_resolution" or name == "y_resolution":
                assert value[0] / value[1] == tags[name][0]
            else:
                value = np.array([value])
                value.squeeze()

                assert np.all(value == tags[name]), "key {}: {} == {}".format(name, value, tags[name])

def test_tags_strips():
    with Tiff("test_data/small_example.tif") as handle:
        tags = handle.read_tags()

    with tifffile.TiffFile("test_data/small_example.tif") as handle:
        page1 = handle.pages[0]
        for tag in page1.tags.values():
            name, value = tag.name, tag.value
            if isinstance(value, bytes):
                value = value.decode()
                assert value == tags[name], "key {}: {} == {}".format(name, value, tags[name])
            elif name == "x_resolution" or name == "y_resolution":
                assert value[0] / value[1] == tags[name][0]
            else:
                value = np.array([value])
                value.squeeze()

                assert np.all(value == tags[name]), "key {}: {} == {}".format(name, value, tags[name])

def test_tags_rbg():
    with Tiff("test_data/rgb_sample.tif") as handle:
        tags = handle.read_tags()

    with tifffile.TiffFile("test_data/rgb_sample.tif") as handle:
        page1 = handle.pages[0]
        for tag in page1.tags.values():
            name, value = tag.name, tag.value
            if isinstance(value, bytes):
                value = value.decode()
                assert value == tags[name], "key {}: {} == {}".format(name, value, tags[name])
            elif name == "x_resolution" or name == "y_resolution":
                assert value[0] / value[1] == tags[name][0]
            else:
                value = np.array([value])
                value.squeeze()

                assert np.all(value == tags[name]), "key {}: {} == {}".format(name, value, tags[name])

def test_tags_bigtif():
    with Tiff("test_data/bigtif_example_tiled.tif") as handle:
        tags = handle.read_tags()

    with tifffile.TiffFile("test_data/bigtif_example_tiled.tif") as handle:
        page1 = handle.pages[0]
        for tag in page1.tags.values():
            name, value = tag.name, tag.value
            if isinstance(value, bytes):
                value = value.decode()
                assert value == tags[name], "key {}: {} == {}".format(name, value, tags[name])
            elif name == "x_resolution" or name == "y_resolution":
                assert value[0] / value[1] == tags[name][0]
            else:
                value = np.array([value])
                value.squeeze()

                assert np.all(value == tags[name]), "key {}: {} == {}".format(name, value, tags[name])

