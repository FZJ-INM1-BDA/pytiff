//
// Created by philipp on 06.04.16.
//

#ifndef BIGTIFF_TIFFTILE_H
#define BIGTIFF_TIFFTILE_H

#include "tiff.h"
#include "tiffio.h"

extern short get_samples_per_pixel(const char* filename);
extern short get_n_bits(const char* filename);
extern void read_single_tile(TIFF* tif, uint32 x,uint32 y, int8* buf);
#endif //BIGTIFF_TIFFTILE_H
