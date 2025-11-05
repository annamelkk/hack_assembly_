#ifndef DRAW_H
#define DRAW_H

#include <stdint.h>
#include <stdio.h>

#define WIDTH 512
#define HEIGHT 256

#define WORDS_PR (WIDTH / 16)
#define SIZE (HEIGHT * WORDS_PR)

extern unsigned short	screen[SIZE]; // 8192 words, like in hack

void	clear_image(unsigned char color);
void	set_pixel(int x, int y, unsigned char color);
void	horizontal_line(int y, int x1, int x2, unsigned char color);
void	vertical_line(int y, int x1, int x2, unsigned char color);
void	write_bmp(const char *filename);

#endif
