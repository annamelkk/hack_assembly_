#include <stdio.h>
#include "draw.h"

int	main(void)
{
	// declare test coordinates
	int x1 = 50;
	int x2 = 400;
	int y1 = 30;
	int y2 = 200;

	// clear screen to white (0 = white, 1 = black)
	clear_image(0);

	// draw some test lines
	horizontal_line(y1, x1, x2, 1);  // black horizontal line
	vertical_line(x1, y1, y2, 1);    // vertical line at left edge
	vertical_line(x2, y1, y2, 1);    // vertical line at right edge
	horizontal_line(y2, x2, x1, 1);

	// draw some random test pixels
	set_pixel(256, 128, 1);
	set_pixel(100, 100, 1);

	// finally write to BMP file to visualize
	write_bmp("output.bmp");

	printf("Image written to output.bmp\n");
	return 0;
}

