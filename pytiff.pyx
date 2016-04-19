cimport ctiff
from libcpp.string cimport string
from cpython cimport bool
cimport numpy as np
import numpy as np
from math import ceil

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
  cdef ctiff.TIFF* tiff_handle
  cdef public short samples_per_pixel
  cdef short[:] n_bits_view
  cdef short sample_format, n_pages
  cdef bool closed
  cdef unsigned int image_width, image_length, tile_width, tile_length

  def __cinit__(self, const string filename):
    self.closed = False
    self.n_pages = 0
    self.tiff_handle = ctiff.TIFFOpen(filename.c_str(), "r")
    self._init_page()

  def _init_page(self):
    self.samples_per_pixel = 1
    ctiff.TIFFGetField(self.tiff_handle, 277, &self.samples_per_pixel)
    cdef np.ndarray[np.int16_t, ndim=1] bits_buffer = np.zeros(self.samples_per_pixel, dtype=np.int16)
    ctiff.TIFFGetField(self.tiff_handle, 258, <ctiff.ttag_t*>bits_buffer.data)
    self.n_bits_view = bits_buffer

    self.sample_format = 1
    ctiff.TIFFGetField(self.tiff_handle, 339, &self.sample_format)

    ctiff.TIFFGetField(self.tiff_handle, 256, &self.image_width)
    ctiff.TIFFGetField(self.tiff_handle, 257, &self.image_length)

    ctiff.TIFFGetField(self.tiff_handle, 322, &self.tile_width)
    ctiff.TIFFGetField(self.tiff_handle, 323, &self.tile_length)

  def close(self):
    if not self.closed:
      ctiff.TIFFClose(self.tiff_handle)
      self.closed = True
      return

  def __dealloc__(self):
    if not self.closed:
      ctiff.TIFFClose(self.tiff_handle)

  @property
  def size(self):
    return self.image_width, self.image_length

  @property
  def n_bits(self):
    return np.array(self.n_bits_view)

  @property
  def dtype(self):
    return TYPE_MAP[self.sample_format][self.n_bits[0]]

  @property
  def current_page(self):
    return ctiff.TIFFCurrentDirectory(self.tiff_handle)

  def set_page(self, value):
    ctiff.TIFFSetDirectory(self.tiff_handle, value)
    self._init_page()

  @property
  def number_of_pages(self):
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

  def __enter__(self):
    return self

  def __exit__(self, type, value, traceback):
    self.close()

  def get(self, x_range=None, y_range=None):
    if not self.tile_width:
      raise Exception("Image is not tiled!")
    cdef unsigned int z_size, start_x, start_y, start_x_offset, start_y_offset
    cdef unsigned int end_x, end_y, end_x_offset, end_y_offset

    # use rgba if no greyscale image
    z_size = 1
    if self.samples_per_pixel > 1:
      z_size = 4

    if x_range is None:
      x_range = (0, self.image_width)
    if y_range is None:
      y_range = (0, self.image_length)

    shape = (x_range[1] - x_range[0], y_range[1] - y_range[0], z_size)

    start_x = x_range[0] // self.tile_width
    start_y = y_range[0] // self.tile_length
    end_x = ceil(float(x_range[1]) / self.tile_width)
    end_y = ceil(float(y_range[1]) / self.tile_length)
    offset_x = start_x * self.tile_width
    offset_y = start_y * self.tile_length

    large = (end_x - start_x) * self.tile_width, (end_y - start_y) * self.tile_length, z_size

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
        tmp = self._read_tile(real_x, real_y)
        e_x = np_x + tmp.shape[0]
        e_y = np_y + tmp.shape[1]

        large_buf[np_x:e_x, np_y:e_y] = tmp
        np_x += self.tile_width

      np_y += self.tile_length

    arr_buf = large_buf[x_range[0]-offset_x:x_range[1]-offset_x, y_range[0]-offset_y:y_range[1]-offset_y]
    if arr_buf.ndim == 2:
      dims = (1,0)
    else:
      dims = (1,0,2)

    return arr_buf.transpose(dims)

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

    return self.get(x_range, y_range)

  cdef _read_tile(self, unsigned int x, unsigned int y):
    if self.samples_per_pixel > 1:
      return self._read_rgb_tile(x, y)
    cdef np.ndarray buffer = np.zeros((self.tile_width, self.tile_length),dtype=self.dtype)
    cdef ctiff.tsize_t bytes = ctiff.TIFFReadTile(self.tiff_handle, <void *>buffer.data, x, y, 0, 0)
    buffer = buffer.T
    if bytes == -1:
      raise Exception("Tiled reading not possible")
    return buffer

  cdef _read_rgb_tile(self, unsigned int x, unsigned int y):
    cdef np.ndarray[np.uint32_t, ndim=2] buffer = np.zeros((self.tile_width, self.tile_length), dtype=np.uint32)
    cdef ctiff.tsize_t bytes = ctiff.TIFFReadRGBATile(self.tiff_handle, x, y, <unsigned int *>buffer.data)
    cdef np.ndarray[np.uint8_t, ndim=3] rgb_buffer = _get_rgb(buffer)
    return rgb_buffer.transpose(1,0,2)
