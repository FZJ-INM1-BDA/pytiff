//
// Created by philipp on 05.04.16.
//

#include "tifftile.h"
#include <iostream>
static const std::string C_FILENAME = "big_tiff_sample.tif";

/*tdata_t read_tiles(const std::string& filename) {
    uint32 x, y;
    uint32 image_length, image_width;
    uint32 tile_length, tile_width;
    tdata_t buf;

    TIFF* tif = TIFFOpen(filename.c_str(),"r");

    TIFFGetField(tif, TIFFTAG_IMAGEWIDTH, &image_width);
    TIFFGetField(tif, TIFFTAG_IMAGELENGTH, &image_length);

    TIFFGetField(tif, TIFFTAG_TILEWIDTH, &tile_width);
    TIFFGetField(tif, TIFFTAG_TILELENGTH, &tile_length);
    buf = _TIFFmalloc(TIFFTileSize(tif));

    for (y = 0; y < image_length; y += tile_length) {
        for (x = 0; x < image_width; x += tile_width) {
            TIFFReadTile(tif, buf, x, y, 0, 0);
        }
    }
    _TIFFfree(buf);
    TIFFClose(tif);

}*/
int tile_width(const std::string filename) {
  int tw;
  TIFF* tif = TIFFOpen(filename.c_str(), "r");
  TIFFGetField(tif, TIFFTAG_TILEWIDTH, &tw);
  TIFFClose(tif);
  return tw;
}

int tile_length(const std::string filename) {
  int tl;
  TIFF* tif = TIFFOpen(filename.c_str(), "r");
  TIFFGetField(tif, TIFFTAG_TILELENGTH, &tl);
  TIFFClose(tif);
  return tl;
}

short get_samples_per_pixel(const std::string& filename) {
    TIFF* tif = TIFFOpen(filename.c_str(), "r");
    short n_samples = -1;
    TIFFGetField(tif, TIFFTAG_SAMPLESPERPIXEL, &n_samples);
    TIFFClose(tif);
    return n_samples;
}

short get_n_bits(const std::string& filename) {
    TIFF* tif = TIFFOpen(filename.c_str(), "r");
    short n_samples = get_samples_per_pixel(filename);
    short bits[n_samples];
    TIFFGetField(tif, TIFFTAG_BITSPERSAMPLE, bits);
    TIFFClose(tif);
    short res = bits[0];
    return res;
}

void read_single_tile(TIFF* tif, uint32 x,uint32 y, int8* buf) {
  TIFFReadTile(tif, reinterpret_cast<void*>(buf), x, y, 0, 0);
}


void read_first_tile(const std::string filename, void* buf) {
  TIFF* tif = TIFFOpen(filename.c_str(), "r");
  TIFFReadTile(tif, buf, 0, 0, 0, 0);
  TIFFClose(tif);
}

int main() {
  std::cout << get_n_bits(C_FILENAME) << std::endl;
}
