#ifndef CAVIS_SETTINGS_H
#define CAVIS_SETTINGS_H

#include <stdbool.h>
#include <stddef.h>

#include "config.h"

enum {
    CH_LAYOUT = 1 << 0,
    CH_DSP    = 1 << 1,
    CH_AUDIO  = 1 << 2,
};

typedef struct settings_ui settings_ui;

settings_ui *settings_new(void);
void settings_free(settings_ui *s);
/* edit cfg according to key; set bits in *changed for applied settings */
void settings_key(settings_ui *s, cavis_config *cfg, int key, unsigned *changed);
/* render the full settings screen into out */
void settings_draw(const settings_ui *s, const cavis_config *cfg, char *out,
                   size_t *out_len, size_t cap);

#endif
