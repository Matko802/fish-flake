#ifndef CAVIS_RENDER_H
#define CAVIS_RENDER_H

#include <stdbool.h>
#include <stddef.h>

typedef struct {
    unsigned rows;
    unsigned cols;
    size_t bar_width;
    size_t bar_spacing;
    size_t num_bars;
    bool gradient;
    unsigned char *prev;
} renderer_t;

void renderer_init(renderer_t *r, unsigned rows, unsigned cols, size_t bar_width,
                   size_t bar_spacing, size_t num_bars, bool gradient);
void renderer_resize(renderer_t *r, unsigned rows, unsigned cols, size_t num_bars);
void renderer_free(renderer_t *r);
/* values are normalized 0..1; changed cells are appended to out as ANSI */
void renderer_draw(renderer_t *r, const double *values, char *out, size_t *out_len,
                   size_t cap);

#endif
