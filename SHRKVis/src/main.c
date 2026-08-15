#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include "audio.h"
#include "config.h"
#include "dsp.h"
#include "render.h"
#include "term.h"

static volatile sig_atomic_t g_sig = 0;
static volatile sig_atomic_t g_resize = 0;

static void on_signal(int sig) {
    (void)sig;
    g_sig = 1;
}

static void on_winch(int sig) {
    (void)sig;
    g_resize = 1;
}

static void usage(void) {
    printf("usage: cavis [-p config_file]\n");
    printf("  q - quit\n");
}

int main(int argc, char **argv) {
    const char *cfgpath = NULL;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-p") == 0 && i + 1 < argc) {
            cfgpath = argv[++i];
        } else if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0) {
            usage();
            return 0;
        } else {
            fprintf(stderr, "cavis: unknown option '%s'\n", argv[i]);
            usage();
            return 1;
        }
    }

    cavis_config cfg;
    config_default(&cfg);

    char *path = NULL;
    if (cfgpath) {
        path = strdup(cfgpath);
        if (!config_load(&cfg, path)) {
            fprintf(stderr, "cavis: error loading config %s\n", path);
            free(path);
            config_free(&cfg);
            return 1;
        }
    } else {
        path = config_default_path();
        if (access(path, F_OK) == 0 && !config_load(&cfg, path))
            fprintf(stderr, "cavis: error loading config %s, using defaults\n", path);
    }
    free(path);

    if (cfg.bar_width < 1)
        cfg.bar_width = 1;
    if (cfg.framerate < 1)
        cfg.framerate = 1;
    if (cfg.framerate > 240)
        cfg.framerate = 240;
    if (cfg.sensitivity < 0.1)
        cfg.sensitivity = 0.1;
    if (cfg.noise_reduction < 0.0)
        cfg.noise_reduction = 0.0;
    if (cfg.noise_reduction > 1.0)
        cfg.noise_reduction = 1.0;
    if (cfg.lower_cutoff < 1)
        cfg.lower_cutoff = 1;
    if (cfg.higher_cutoff < cfg.lower_cutoff)
        cfg.higher_cutoff = cfg.lower_cutoff + 1;

    unsigned rows, cols;
    if (!term_winsize(1, &rows, &cols)) {
        rows = 24;
        cols = 80;
    }

    size_t bars = cfg.bars ? cfg.bars
                           : (size_t)(cols / (cfg.bar_width + cfg.bar_spacing));
    if (bars < 1)
        bars = 1;

    dsp_t dsp;
    dsp_init(&dsp, bars, cfg.sample_rate, cfg.autosens, cfg.noise_reduction,
             cfg.lower_cutoff, cfg.higher_cutoff);

    audio_t audio;
    audio_init(&audio, dsp.input_buffer_size);
    audio_start(&audio, cfg.source, cfg.sample_rate, cfg.channels);

    if (!term_raw_enter(0)) {
        fprintf(stderr, "cavis: not a terminal\n");
        audio_stop(&audio);
        dsp_free(&dsp);
        config_free(&cfg);
        return 1;
    }

    struct sigaction sa;
    memset(&sa, 0, sizeof sa);
    sa.sa_handler = on_signal;
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);
    struct sigaction win;
    memset(&win, 0, sizeof win);
    win.sa_handler = on_winch;
    sigaction(SIGWINCH, &win, NULL);

    printf("\x1b[2J\x1b[H\x1b[?25l");
    fflush(stdout);

    renderer_t rnd;
    renderer_init(&rnd, rows, cols, cfg.bar_width, cfg.bar_spacing, bars, cfg.gradient);

    double *heights = malloc(bars * sizeof *heights);
    double sens = cfg.sensitivity / 100.0;
    char *out = malloc((size_t)1 << 20);

    struct timespec next;
    clock_gettime(CLOCK_MONOTONIC, &next);
    long frame_ns = (long)(1e9 / cfg.framerate);

    int rc = 0;
    while (!g_sig) {
        int key = term_read_key(0);
        if (key == 'q' || key == 'Q' || key == 3)
            break;

        if (g_resize) {
            g_resize = 0;
            unsigned nr, nc;
            if (term_winsize(1, &nr, &nc) && nr > 0 && nc > 0 &&
                (nr != rows || nc != cols)) {
                size_t new_bars = cfg.bars
                    ? cfg.bars
                    : (size_t)(nc / (cfg.bar_width + cfg.bar_spacing));
                if (new_bars < 1)
                    new_bars = 1;
                cols = nc;
                rows = nr;
                bars = new_bars;
                double saved_sens = dsp.sens;
                bool saved_sens_init = dsp.sens_init;
                dsp_free(&dsp);
                dsp_init(&dsp, bars, cfg.sample_rate, cfg.autosens,
                         cfg.noise_reduction, cfg.lower_cutoff, cfg.higher_cutoff);
                dsp.sens = saved_sens;
                dsp.sens_init = saved_sens_init;
                free(heights);
                heights = malloc(bars * sizeof *heights);
                renderer_resize(&rnd, rows, cols, bars);
                printf("\x1b[2J\x1b[H");
                fflush(stdout);
            }
        }

        const double *samples = NULL;
        size_t n = audio_consume(&audio, &samples);
        if (n > 0)
            dsp_execute(&dsp, samples, n, heights);
        if (audio_failed(&audio)) {
            fprintf(stderr, "\ncavis: audio input failed: %s\n", audio_error(&audio));
            rc = 1;
            break;
        }

        for (size_t i = 0; i < bars; i++)
            heights[i] *= sens;

        size_t olen = 0;
        renderer_draw(&rnd, heights, out, &olen, (size_t)1 << 20);
        if (olen) {
            fwrite(out, 1, olen, stdout);
            fflush(stdout);
        }

        next.tv_nsec += frame_ns;
        next.tv_sec += next.tv_nsec / 1000000000L;
        next.tv_nsec %= 1000000000L;
        clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &next, NULL);
    }

    printf("\x1b[?25h\x1b[0m\x1b[J");
    fflush(stdout);
    term_raw_restore(0);

    audio_stop(&audio);
    renderer_free(&rnd);
    dsp_free(&dsp);
    free(heights);
    free(out);
    config_free(&cfg);
    return rc;
}
