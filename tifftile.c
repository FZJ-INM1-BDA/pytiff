//
// Created by philipp on 05.04.16.
//

#include "tifftile.h"
#include "stdio.h"
static const char* C_FILENAME = "big_tiff_sample.tif";

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

short get_samples_per_pixel(const char* filename) {
    TIFF* tif = TIFFOpen(filename, "r");
    short n_samples = -1;
    TIFFGetField(tif, TIFFTAG_SAMPLESPERPIXEL, &n_samples);
    TIFFClose(tif);
    return n_samples;
}

short get_n_bits(const char* filename) {
    TIFF* tif = TIFFOpen(filename, "r");
    short n_samples = get_samples_per_pixel(filename);
    short bits[n_samples];
    TIFFGetField(tif, TIFFTAG_BITSPERSAMPLE, bits);
    TIFFClose(tif);
    short res = bits[0];
    return res;
}

void read_single_tile(TIFF* tif, uint32 x,uint32 y, int8* buf) {
  TIFFReadTile(tif, (void*)(buf), x, y, 0, 0);
}

int main() {
  printf("%hi\n", get_n_bits(C_FILENAME));
}
