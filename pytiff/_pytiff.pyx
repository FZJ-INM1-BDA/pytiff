#cython: c_string_type=str, c_string_encoding=ascii
"""
pytiff is a python wrapper for the libtiff c api written in cython. It is python 2 and 3 compatible.
While there are some missing features, it supports reading chunks of tiled greyscale tif images as well as basic reading for color images.
Apart from that multipage tiffs are supported.
"""

cimport ctiff
from libcpp.string cimport string
from cpython cimport bool
cimport numpy as np
import numpy as np
from math import ceil
import re

TYPE_MAP = {
  1: {
    8: np.uint8,
    16: np.uint16,
    32: np.uint32,
    64: np.uint64
  },
  2: {
    8: np.int8,
    16: np.int16,
    32: np.int32,
    64: np.int64
  },
  3: {
    8: None,
    16: np.float16,
    32: np.float32,
    64: np.float64
  }
}

cdef unsigned int SAMPLE_FORMAT = 339
cdef unsigned int SAMPLES_PER_PIXEL = 277
cdef unsigned int BITSPERSAMPLE = 258
cdef unsigned int IMAGEWIDTH = 256
cdef unsigned int IMAGELENGTH = 257
cdef unsigned int TILEWIDTH = 322
cdef unsigned int TILELENGTH = 323
cdef unsigned int EXTRA_SAMPLES = 338

def tiff_version_raw():
  """Return the raw version string of libtiff."""
  return ctiff.TIFFGetVersion()

def tiff_version():
  """Parse the version of libtiff and return it."""
  cdef string str_version = tiff_version_raw()
  m = re.search("(?<=[Vv]ersion )\d+\.\d+\.?\d*", str_version)
  return m.group(0)

class NotTiledError(Exception):
  def __init__(self, message):
    self.message = message

cdef _get_rgb(np.ndarray[np.uint32_t, ndim=2] inp):
  shape = (inp.shape[0], inp.shape[1], 4)
  cdef np.ndarray[np.uint8_t, ndim=3] rgb = np.zeros(shape, np.uint8)

  cdef unsigned long int row, col
  for row in range(shape[0]):
    for col in range(shape[1]):
      rgb[row, col, 0] = ctiff.TIFFGetR(inp[row, col])
      rgb[row, col, 1] = ctiff.TIFFGetG(inp[row, col])
      rgb[row, col, 2] = ctiff.TIFFGetB(inp[row, col])
      rgb[row, col, 3] = ctiff.TIFFGetA(inp[row, col])

  return rgb

cdef class Tiff:
  """The Tiff class handles tiff files.

  The class is able to read chunked greyscale images as well as basic reading of color images.
  Currently writing tiff files is not supported.

  Examples:
    >>> with pytiff.Tiff("tiff_file.tif") as f:
    >>>   chunk = f[100:300, 50:100]
    >>>   print(type(chunk))
    >>>   print(chunk.shape)
    numpy.ndarray
    (200, 50)

  Args:
    filename (string): The filename of the tiff file.
  """
  cdef ctiff.TIFF* tiff_handle
  cdef public short samples_per_pixel
  cdef short[:] n_bits_view
  cdef short sample_format, n_pages, extra_samples
  cdef bool closed, cached
  cdef unsigned int image_width, image_length, tile_width, tile_length
  cdef object cache

  def __cinit__(self, const string filename):
    self.closed = True
    self.n_pages = 0
    self.tiff_handle = ctiff.TIFFOpen(filename.c_str(), "r")
    if self.tiff_handle is NULL:
      raise IOError("file not found!")
    self.closed = False
    self._init_page()

  def _init_page(self):
    """Initialize page specific attributes."""
    self.samples_per_pixel = 1
    ctiff.TIFFGetField(self.tiff_handle, SAMPLES_PER_PIXEL, &self.samples_per_pixel)
    cdef np.ndarray[np.int16_t, ndim=1] bits_buffer = np.zeros(self.samples_per_pixel, dtype=np.int16)
    ctiff.TIFFGetField(self.tiff_handle, BITSPERSAMPLE, <ctiff.ttag_t*>bits_buffer.data)
    self.n_bits_view = bits_buffer

    self.sample_format = 1
    ctiff.TIFFGetField(self.tiff_handle, SAMPLE_FORMAT, &self.sample_format)

    ctiff.TIFFGetField(self.tiff_handle, IMAGEWIDTH, &self.image_width)
    ctiff.TIFFGetField(self.tiff_handle, IMAGELENGTH, &self.image_length)

    ctiff.TIFFGetField(self.tiff_handle, TILEWIDTH, &self.tile_width)
    ctiff.TIFFGetField(self.tiff_handle, TILELENGTH, &self.tile_length)

    # get extra samples
    cdef np.ndarray[np.int16_t, ndim=1] extra = -np.ones(self.samples_per_pixel, dtype=np.int16)
    ctiff.TIFFGetField(self.tiff_handle, EXTRA_SAMPLES, <short *>extra.data)
    self.extra_samples = 0
    for i in range(self.samples_per_pixel):
      if extra[i] != -1:
        self.extra_samples += 1

    self.cached = False

  def close(self):
    """Close the filehandle."""
    if not self.closed:
      ctiff.TIFFClose(self.tiff_handle)
      self.closed = True
      return

  def __dealloc__(self):
    if not self.closed:
      ctiff.TIFFClose(self.tiff_handle)

  @property
  def mode(self):
    """Mode of the current image. Can either be 'rgb' or 'greyscale'.

    'rgb' is returned if the sampels per pixel are larger than 1. This means 'rgb' is always returned
    if the image is not 'greyscale'.
    """
    if self.samples_per_pixel > 1:
      return "rgb"
    else:
      return "greyscale"

  @property
  def size(self):
    """Returns a tuple with the current image size.

    size is equal to numpys shape attribute.

    Returns:
      tuple: `(image height, image width)`

      This is equal to:
      `(number_of_rows, number_of_columns)`
    """
    return self.image_length, self.image_width

  @property
  def n_bits(self):
    """Returns an array with the bit size for each sample of a pixel."""
    return np.array(self.n_bits_view)

  @property
  def dtype(self):
    """Maps the image data type to an according numpy type.

    Returns:
      type: numpy dtype of the image.

      If the mode is 'rgb', the dtype is always uint8. Most times a rgb image is saved as a
      uint32 array. One value is containing all four values of an RGBA image. Thus the dtype of the numpy array
      is uint8.

      If the mode is 'greyscale', the dtype is the type of the first sample.
      Since greyscale images only have one sample per pixel, this resembles the general dtype.
    """
    if self.mode == "rgb":
      return np.uint8
    return TYPE_MAP[self.sample_format][self.n_bits[0]]

  @property
  def current_page(self):
    """Current page/directory of the tiff file.

    Returns:
      int: index of the current page/directory.
    """
    return ctiff.TIFFCurrentDirectory(self.tiff_handle)

  def set_page(self, value):
    """Set the page/directory of the tiff file.

    Args:
      value (int): page index
    """
    ctiff.TIFFSetDirectory(self.tiff_handle, value)
    self._init_page()

  @property
  def number_of_pages(self):
    """number of pages/directories in the tiff file.

    Returns:
      int: number of pages/directories
    """
    # dont use
    # fails if only one directory
    # ctiff.TIFFNumberOfDirectories(self.tiff_handle)
    current_dir = self.current_page
    if self.n_pages != 0:
      return self.n_pages
    else:
      cont = 1
      while cont:
        self.n_pages += 1
        cont = ctiff.TIFFReadDirectory(self.tiff_handle)
      ctiff.TIFFSetDirectory(self.tiff_handle, current_dir)
    return self.n_pages

  @property
  def n_samples(self):
    cdef short samples_in_file = self.samples_per_pixel - self.extra_samples
    return samples_in_file

  def is_tiled(self):
    """Return True if image is tiled, else False."""
    cdef np.ndarray buffer = np.zeros((self.tile_length, self.tile_width, self.samples_per_pixel - self.extra_samples),dtype=self.dtype).squeeze()
    cdef ctiff.tsize_t bytes = ctiff.TIFFReadTile(self.tiff_handle, <void *>buffer.data, 0, 0, 0, 0)
    if bytes == -1 or not self.tile_width:
      return False
    return True

  def __enter__(self):
    return self

  def __exit__(self, type, value, traceback):
    self.close()

  def load_all(self):
    """Load the image at once.

    If n_samples > 1 a rgba image is returned, else a greyscale image is assumed.

    Returns:
      array_like: RGBA image (3 dimensions) or Greyscale (2 dimensions)
    """
    if self.cached:
      return self.cache
    if self.n_samples > 1:
      data = self._load_all_rgba()
    else:
      data = self._load_all_grey()

    self.cache = data
    self.cached = True
    return data

  def _load_all_rgba(self):
    """Loads an image at once. Returns an RGBA image."""
    cdef np.ndarray buffer
    shape = self.size
    buffer = np.zeros(shape, dtype=np.uint32)
    ctiff.TIFFReadRGBAImage(self.tiff_handle, self.image_width, self.image_length, <unsigned int*>buffer.data, 0)
    rgb = _get_rgb(buffer)
    rgb = np.flipud(rgb)
    return rgb

  def _load_all_grey(self):
    """Loads an image at once. Returns a greyscale image."""
    cdef np.ndarray total = np.zeros(self.size, dtype=self.dtype)
    cdef np.ndarray buffer = np.zeros(self.image_width, dtype=self.dtype)

    for i in range(self.image_length):
      ctiff.TIFFReadScanline(self.tiff_handle,<void*> buffer.data, i, 0)
      total[i] = buffer
    return total

  def load_tiled(self, y_range, x_range):
    cdef unsigned int z_size, start_x, start_y, start_x_offset, start_y_offset
    cdef unsigned int end_x, end_y, end_x_offset, end_y_offset
    if not self.tile_width:
      raise NotTiledError("Image is not tiled!")

    # use rgba if no greyscale image
    z_size = self.n_samples

    shape = (y_range[1] - y_range[0], x_range[1] - x_range[0], z_size)

    start_x = x_range[0] // self.tile_width
    start_y = y_range[0] // self.tile_length
    end_x = ceil(float(x_range[1]) / self.tile_width)
    end_y = ceil(float(y_range[1]) / self.tile_length)
    offset_x = start_x * self.tile_width
    offset_y = start_y * self.tile_length

    large = (end_y - start_y) * self.tile_length, (end_x - start_x) * self.tile_width, z_size

    cdef np.ndarray large_buf = np.zeros(large, dtype=self.dtype).squeeze()
    cdef np.ndarray arr_buf = np.zeros(shape, dtype=self.dtype).squeeze()
    cdef unsigned int np_x, np_y
    np_x = 0
    np_y = 0
    for current_y in np.arange(start_y, end_y):
      np_x = 0
      for current_x in np.arange(start_x, end_x):
        real_x = current_x * self.tile_width
        real_y = current_y * self.tile_length
        tmp = self._read_tile(real_y, real_x)
        e_x = np_x + tmp.shape[1]
        e_y = np_y + tmp.shape[0]

        large_buf[np_y:e_y, np_x:e_x] = tmp
        np_x += self.tile_width

      np_y += self.tile_length

    arr_buf = large_buf[y_range[0]-offset_y:y_range[1]-offset_y, x_range[0]-offset_x:x_range[1]-offset_x]
    return arr_buf

  def get(self, y_range=None, x_range=None):
    """Function to load a chunk of an image.

    Should not be used. Instead use numpy style slicing.

    Examples:
      >>> with pytiff.Tiff("tiffile.tif") as f:
      >>>   total = f[:, :] # f[:]
      >>>   part = f[100:200,:]
    """

    if x_range is None:
      x_range = (0, self.image_width)
    if y_range is None:
      y_range = (0, self.image_length)

    cdef np.ndarray res, tmp
    try:
      res = self.load_tiled(y_range, x_range)
    except NotTiledError as e:
      print(e.message)
      print("Warning: chunks not available! Loading all data!")
      tmp = self.load_all()
      res = tmp[y_range[0]:y_range[1], x_range[0]:x_range[1]]

    return res

  def __getitem__(self, index):
    if not isinstance(index, tuple):
      if isinstance(index, slice):
        index = (index, slice(None,None,None))
      else:
        raise Exception("Only slicing is supported")
    elif len(index) < 3:
      index = index[0],index[1],0

    if not isinstance(index[0], slice) or not isinstance(index[1], slice):
      raise Exception("Only slicing is supported")

    x_range = np.array((index[1].start, index[1].stop))
    if x_range[0] is None:
      x_range[0] = 0
    if x_range[1] is None:
      x_range[1] = self.image_width

    y_range = np.array((index[0].start, index[0].stop))
    if y_range[0] is None:
      y_range[0] = 0
    if y_range[1] is None:
      y_range[1] = self.image_length

    return self.get(y_range, x_range)

  cdef _read_tile(self, unsigned int y, unsigned int x):
    cdef np.ndarray buffer = np.zeros((self.tile_length, self.tile_width, self.n_samples),dtype=self.dtype).squeeze()
    cdef ctiff.tsize_t bytes = ctiff.TIFFReadTile(self.tiff_handle, <void *>buffer.data, x, y, 0, 0)
    if bytes == -1:
      raise NotTiledError("Tiled reading not possible")
    return buffer
