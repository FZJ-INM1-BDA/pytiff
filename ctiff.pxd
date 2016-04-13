TIFFTAG_SAMPLESPERPIXEL = 277

cdef extern from "tifftile.h":
  short get_samples_per_pixel(const char* filename)
  short get_n_bits(const char* filename)
