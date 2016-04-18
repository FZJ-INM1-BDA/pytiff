cimport ctiff
from libcpp.string cimport string
from cpython cimport bool
cimport numpy as np
import numpy as np

from math import ceil

cdef class Tiff:
  cdef ctiff.TIFF* tiff_handle
  cdef public short samples_per_pixel
  cdef short[:] n_bits_view
  cdef short sample_format
  cdef bool closed
  cdef unsigned int image_width, image_length, tile_width, tile_length

  def __cinit__(self, const string filename):
    self.closed = False
    self.tiff_handle = ctiff.TIFFOpen(filename.c_str(), "r")
    self.samples_per_pixel = 1
    ctiff.TIFFGetField(self.tiff_handle, 277, &self.samples_per_pixel)
    cdef np.ndarray[np.int16_t, ndim=1] bits_buffer = np.zeros(self.samples_per_pixel, dtype=np.int16)
    ctiff.TIFFGetField(self.tiff_handle, 258, <ctiff.ttag_t*>bits_buffer.data)
    self.n_bits_view = bits_buffer

    self.sample_format = -5
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
    if self.n_bits[0] == 8:
      return np.uint8
    elif self.n_bits[0] == 16:
      return np.uint16
    elif self.n_bits[0] == 32:
      return np.uint32
    elif self.n_bits[0] == 64:
      return np.uint64

  def __enter__(self):
    return self

  def __exit__(self, type, value, traceback):
    self.close()

  def get(self, x_range=None, y_range=None):
    if not self.tile_width:
      raise Exception("Image is not tiled!")

    cdef unsigned int start_x, start_y, start_x_offset, start_y_offset
    cdef unsigned int end_x, end_y, end_x_offset, end_y_offset
    if x_range is None:
      x_range = (0, self.image_width)
    if y_range is None:
      y_range = (0, self.image_length)

    shape = (x_range[1] - x_range[0], y_range[1] - y_range[0])


    cdef int start_x = x_range[0] // self.tile_width
    cdef int start_y = y_range[0] // self.tile_length
    cdef int end_x = ceil(float(x_range[1]) / self.tile_width)
    cdef int end_y = ceil(float(y_range[1]) / self.tile_length)
    cdef unsigned int offset_x = start_x * self.tile_width
    cdef unsigned int offset_y = start_y * self.tile_length

    large = (end_x - start_x) * self.tile_width, (end_y - start_y) * self.tile_length

    cdef np.ndarray large_buf = np.zeros(large, dtype=self.dtype)
    cdef np.ndarray arr_buf = np.zeros(shape, dtype=self.dtype)
    cdef unsigned int np_x, np_y
    np_x = 0
    np_y = 0
    for current_y in np.arange(start_y, end_y):
      np_x = 0
      for current_x in np.arange(start_x, end_x):
        real_x = current_x * self.tile_width
        real_y = current_y * self.tile_length
        tmp = self._read_tile(real_x, real_y).T

        e_x = np_x + tmp.shape[0]
        e_y = np_y + tmp.shape[1]

        large_buf[np_x:e_x, np_y:e_y] = tmp
        np_x += self.tile_width

      np_y += self.tile_length

    arr_buf = large_buf[x_range[0]-offset_x:x_range[1]-offset_x, y_range[0]-offset_y:y_range[1]-offset_y]
    return arr_buf

  def __getitem__(self, index):
    if isinstance(index, slice):
      index = (index, slice(None,None,None))

    if not isinstance(index[0], slice) or not isinstance(index[1], slice):
      raise Exception("Only slicing is supported")

    x_range = np.array((index[0].start, index[0].stop))
    if x_range[0] is None:
      x_range[0] = 0
    if x_range[1] is None:
      x_range[1] = self.image_width

    y_range = np.array((index[0].start, index[1].stop))
    if y_range[0] is None:
      y_range[0] = 0
    if y_range[1] is None:
      y_range[1] = self.image_length

    return self.get(x_range, y_range)



  def _read_tile(self, unsigned int x, unsigned int y):
    cdef np.ndarray buffer = np.zeros((self.tile_width, self.tile_length),dtype=self.dtype)
    cdef ctiff.tsize_t bytes = ctiff.TIFFReadTile(self.tiff_handle, <void *>buffer.data, x, y, 0, 0)
    if bytes == -1:
      raise Exception("Tiled reading not possible")
    return buffer
