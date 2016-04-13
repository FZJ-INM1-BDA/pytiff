cimport ctiff

cpdef samples_per_pixel(const char* name):
  return ctiff.get_samples_per_pixel(name)

cpdef n_bits(const char* name):
  return ctiff.get_n_bits(name)
