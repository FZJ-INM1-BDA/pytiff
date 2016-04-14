from libcpp.string cimport string

cdef extern from "tifftile.h":
  short get_samples_per_pixel(const string filename)
  short get_n_bits(const string filename)
  void read_first_tile(const string filename, void* buf)
  int tile_length(const string filename)
  int tile_width(const string filename)  
