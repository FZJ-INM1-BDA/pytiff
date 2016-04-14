//
// Created by philipp on 06.04.16.
//

#ifndef BIGTIFF_TIFFTILE_H
#define BIGTIFF_TIFFTILE_H

#include <string>
#include "tiff.h"
#include "tiffio.h"

short get_samples_per_pixel(const std::string& filename);
short get_n_bits(const std::string& filename);
void read_single_tile(TIFF* tif, uint32 x,uint32 y, int8* buf);
void read_first_tile(const std::string filename, void* buf);
int tile_length(const std::string filename);
int tile_width(const std::string filename);
#endif //BIGTIFF_TIFFTILE_H
