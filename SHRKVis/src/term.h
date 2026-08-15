#ifndef CAVIS_TERM_H
#define CAVIS_TERM_H

#include <stdbool.h>

bool term_winsize(int fd, unsigned *rows, unsigned *cols);
bool term_raw_enter(int fd);
void term_raw_restore(int fd);
int term_read_key(int fd);

#endif
