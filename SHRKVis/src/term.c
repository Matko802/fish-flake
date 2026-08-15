#include "term.h"

#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>

static struct termios saved;
static bool have_saved = false;

bool term_winsize(int fd, unsigned *rows, unsigned *cols) {
    struct winsize ws;
    if (ioctl(fd, TIOCGWINSZ, &ws) != 0 || ws.ws_row == 0 || ws.ws_col == 0)
        return false;
    *rows = ws.ws_row;
    *cols = ws.ws_col;
    return true;
}

bool term_raw_enter(int fd) {
    struct termios t;
    if (tcgetattr(fd, &t) != 0)
        return false;
    saved = t;
    have_saved = true;
    t.c_lflag &= ~(ICANON | ECHO | ISIG);
    t.c_iflag &= ~(IXON | ICRNL);
    t.c_cc[VMIN] = 0;
    t.c_cc[VTIME] = 0;
    return tcsetattr(fd, TCSANOW, &t) == 0;
}

void term_raw_restore(int fd) {
    if (have_saved)
        tcsetattr(fd, TCSANOW, &saved);
}

int term_read_key(int fd) {
    unsigned char c;
    if (read(fd, &c, 1) == 1)
        return c;
    return -1;
}
