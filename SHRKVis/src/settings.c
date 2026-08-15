#include "settings.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "term.h"

typedef enum {
    S_BARS,
    S_BARW,
    S_SPACING,
    S_FPS,
    S_SENS,
    S_AUTO,
    S_NOISE,
    S_LOW,
    S_HIGH,
    S_GRAD,
    S_RATE,
    S_CH,
    S_COUNT,
} sid;

static const char *const LABELS[S_COUNT] = {
    "bars",
    "bar width",
    "bar spacing",
    "framerate",
    "sensitivity",
    "autosens",
    "noise reduction",
    "lower cutoff",
    "upper cutoff",
    "gradient color",
    "sample rate",
    "channels",
};

static const unsigned RATES[] = { 8000, 11025, 16000, 22050, 32000, 44100,
                                  48000, 96000, 192000 };
#define RATES_N ((int)(sizeof RATES / sizeof RATES[0]))

static long clamp_l(long v, long lo, long hi) {
    if (v < lo)
        v = lo;
    if (v > hi)
        v = hi;
    return v;
}

static double clamp_d(double v, double lo, double hi) {
    if (v < lo)
        v = lo;
    if (v > hi)
        v = hi;
    return v;
}

struct settings_ui {
    int sel;
};

settings_ui *settings_new(void) {
    return calloc(1, sizeof(settings_ui));
}

void settings_free(settings_ui *s) {
    free(s);
}

static void adjust(cavis_config *c, int id, int dir, unsigned *changed) {
    switch (id) {
    case S_BARS: {
        long v = clamp_l((long)c->bars + dir, 0, 256);
        if ((size_t)v != c->bars) {
            c->bars = (size_t)v;
            *changed |= CH_LAYOUT;
        }
        break;
    }
    case S_BARW: {
        long v = clamp_l((long)c->bar_width + dir, 1, 8);
        if ((size_t)v != c->bar_width) {
            c->bar_width = (size_t)v;
            *changed |= CH_LAYOUT;
        }
        break;
    }
    case S_SPACING: {
        long v = clamp_l((long)c->bar_spacing + dir, 0, 4);
        if ((size_t)v != c->bar_spacing) {
            c->bar_spacing = (size_t)v;
            *changed |= CH_LAYOUT;
        }
        break;
    }
    case S_FPS: {
        long v = clamp_l((long)c->framerate + dir * 5, 1, 240);
        if ((unsigned)v != c->framerate) {
            c->framerate = (unsigned)v;
            *changed |= CH_LAYOUT;
        }
        break;
    }
    case S_SENS: {
        double v = clamp_d(c->sensitivity + dir * 5.0, 1.0, 200.0);
        if (v != c->sensitivity) {
            c->sensitivity = v;
            *changed |= CH_LAYOUT;
        }
        break;
    }
    case S_AUTO: {
        bool v = !c->autosens;
        if (v != c->autosens) {
            c->autosens = v;
            *changed |= CH_DSP;
        }
        break;
    }
    case S_NOISE: {
        double v = clamp_d(c->noise_reduction + dir * 0.05, 0.0, 1.0);
        if (v != c->noise_reduction) {
            c->noise_reduction = v;
            *changed |= CH_DSP;
        }
        break;
    }
    case S_LOW: {
        long v = clamp_l((long)c->lower_cutoff + dir * 25, 1, 20000);
        if (v >= (long)c->higher_cutoff)
            v = (long)c->higher_cutoff - 1;
        if ((unsigned)v != c->lower_cutoff) {
            c->lower_cutoff = (unsigned)v;
            *changed |= CH_DSP;
        }
        break;
    }
    case S_HIGH: {
        long v = clamp_l((long)c->higher_cutoff + dir * 500, 50, 24000);
        if (v <= (long)c->lower_cutoff)
            v = (long)c->lower_cutoff + 1;
        if ((unsigned)v != c->higher_cutoff) {
            c->higher_cutoff = (unsigned)v;
            *changed |= CH_DSP;
        }
        break;
    }
    case S_GRAD: {
        bool v = !c->gradient;
        if (v != c->gradient) {
            c->gradient = v;
            *changed |= CH_LAYOUT;
        }
        break;
    }
    case S_RATE: {
        int idx = 0;
        for (int i = 0; i < RATES_N; i++) {
            if (RATES[i] <= c->sample_rate)
                idx = i;
        }
        idx = clamp_l(idx + dir, 0, RATES_N - 1);
        if (RATES[idx] != c->sample_rate) {
            c->sample_rate = RATES[idx];
            *changed |= CH_AUDIO;
        }
        break;
    }
    case S_CH: {
        unsigned v = (c->channels == 1) ? 2 : 1;
        if (v != c->channels) {
            c->channels = v;
            *changed |= CH_AUDIO;
        }
        break;
    }
    }
}

void settings_key(settings_ui *s, cavis_config *cfg, int key, unsigned *changed) {
    switch (key) {
    case KEY_UP:
        s->sel = (s->sel + S_COUNT - 1) % S_COUNT;
        break;
    case KEY_DOWN:
        s->sel = (s->sel + 1) % S_COUNT;
        break;
    case KEY_LEFT:
    case '-':
        adjust(cfg, s->sel, -1, changed);
        break;
    case KEY_RIGHT:
    case '+':
    case '=':
        adjust(cfg, s->sel, +1, changed);
        break;
    default:
        break;
    }
}

static void format_value(const cavis_config *c, int id, char *buf, size_t n) {
    switch (id) {
    case S_BARS:
        if (c->bars == 0)
            snprintf(buf, n, "auto");
        else
            snprintf(buf, n, "%zu", c->bars);
        break;
    case S_AUTO:
    case S_GRAD:
        snprintf(buf, n, "%s", c->autosens ? "on" : "off");
        break;
    case S_NOISE:
        snprintf(buf, n, "%.2f", c->noise_reduction);
        break;
    case S_SENS:
        snprintf(buf, n, "%.0f", c->sensitivity);
        break;
    case S_BARW:
        snprintf(buf, n, "%zu", c->bar_width);
        break;
    case S_SPACING:
        snprintf(buf, n, "%zu", c->bar_spacing);
        break;
    case S_FPS:
        snprintf(buf, n, "%u", c->framerate);
        break;
    case S_LOW:
        snprintf(buf, n, "%u", c->lower_cutoff);
        break;
    case S_HIGH:
        snprintf(buf, n, "%u", c->higher_cutoff);
        break;
    case S_RATE:
        snprintf(buf, n, "%u", c->sample_rate);
        break;
    case S_CH:
        snprintf(buf, n, "%u", c->channels);
        break;
    default:
        buf[0] = '\0';
        break;
    }
}

void settings_draw(const settings_ui *s, const cavis_config *cfg, char *out,
                   size_t *out_len, size_t cap) {
    size_t n = 0;
    n += (size_t)snprintf(out + n, cap - n,
                          "\x1b[2J\x1b[H\x1b[37m  cavis settings\x1b[0m\r\n");
    n += (size_t)snprintf(out + n, cap - n,
                          "  \x1b[90mup/down select, left/right adjust, g close, q quit\x1b[0m\r\n");
    n += (size_t)snprintf(out + n, cap - n, "\r\n");
    for (int id = 0; id < S_COUNT; id++) {
        char val[32];
        format_value(cfg, id, val, sizeof val);
        const char *hi = (id == s->sel) ? "\x1b[7m" : "";
        const char *hi0 = (id == s->sel) ? "\x1b[0m" : "";
        n += (size_t)snprintf(out + n, cap - n, "  %s%-18s %-12s%s\x1b[K\r\n", hi,
                              LABELS[id], val, hi0);
    }
    *out_len = n;
}
