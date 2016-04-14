cimport ctiff
from libcpp.string cimport string
cimport numpy as np
import numpy as np

cpdef samples_per_pixel(const string name):
  return ctiff.get_samples_per_pixel(name)

cpdef n_bits(const string name):
  return ctiff.get_n_bits(name)

cpdef first_tile(const string name):
  width = ctiff.tile_width(name)
  length = ctiff.tile_length(name)
  print(width)
  print(length)
  cdef np.ndarray[np.int16_t, ndim=2, mode="c"] nbuffer = np.zeros((width,length), dtype =np.int16)
  ctiff.read_first_tile(name, <void *>nbuffer.data)
  return nbuffer
