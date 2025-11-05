#include "draw.h"

unsigned short	screen[SIZE]; // 8192 words, like in hack
// function to set the colot of the overall screen
void	clear_image(unsigned char color)
{
	unsigned short fill;
	int i = 0;
	if (color != 1 && color != 0)
		return;
	
	if (color)
		fill = 0xFFFF;
	else 
		fill = 0x0000;
	while (i < SIZE)
	{
		screen[i] = fill;
		i++;
	}

}

void	set_pixel(int x, int y, unsigned char color)
{
	if ( x < 0 || x >= WIDTH || y < 0 || y >= HEIGHT)
      		return ;

	int	word_index = y * WORDS_PR + (x / 16);
	int	bit_index = 15 - (x % 16); // leftomost pixel = bit 15

	if (color)
		screen[word_index] |= (1 << bit_index);
	else
		screen[word_index] &= ~(1 << bit_index);
}

void	horizontal_line(int y, int x1, int x2, unsigned char color)
{
	if ( y < 0 || y >= HEIGHT)
		return ;

	if (x1 > x2)
	{
		int	temp;

		temp = x1;
		x1 = x2;
		x2 = temp;
	}

	int i = x1;
	while (i < x2)
	{
		set_pixel(i, y, color);
		i++;
	}
}

void	vertical_line(int x, int y1, int y2, unsigned char color)
{
	if ( x < 0 || x >= WIDTH )
		return ;

	if (y1 > y2)
	{
		int	temp;
	
		temp = y1;
		y1 = y2;
		y2 = temp;
	}

	int j = y1;

	while (j < y2)
	{
		set_pixel(x, j, color);
		j++;
	}
}


void	write_bmp(const char *filename)
{
	int row_size = ((WIDTH * 3 + 3) / 4) * 4; // each row for BMP file must be 4 bytes be reqs
	int filesize = 54 + row_size * HEIGHT; // header size + total size of pixel data

	FILE *f = fopen(filename, "wb");
	if (!f) return ;

	// to identify file as bmp
	unsigned char	bmpfileheader[14] = { 'B', 'M', 0,0,0,0, 0,0,0,0, 54,0,0,0 };

	// info header, stores image width, height and other info, setup for 24-bit BMP
	unsigned char	bmpinfoheader[40] = { 40,0,0,0, 0,0,0,0, 0,0,0,0, 1,0,24,0 };
	

	bmpfileheader[ 2] = (unsigned char)(filesize);
	bmpfileheader[ 3] = (unsigned char)(filesize >> 8);
	bmpfileheader[ 4] = (unsigned char)(filesize >> 16);
	bmpfileheader[ 5] = (unsigned char)(filesize >> 24);

	bmpinfoheader[ 4] = (unsigned char)(WIDTH);
	bmpinfoheader[ 5] = (unsigned char)(WIDTH >> 8);
	bmpinfoheader[ 6] = (unsigned char)(WIDTH >> 16);
	bmpinfoheader[ 7] = (unsigned char)(WIDTH >> 24);


	bmpinfoheader[ 8] = (unsigned char)(HEIGHT);
	bmpinfoheader[ 9] = (unsigned char)(HEIGHT >> 8);
	bmpinfoheader[10] = (unsigned char)(HEIGHT >> 16);
	bmpinfoheader[11] = (unsigned char)(HEIGHT >> 24);


	// write binary data to the file
	fwrite(bmpfileheader, 1, 14, f);
	fwrite(bmpinfoheader, 1, 40, f);

	int padding = row_size - (WIDTH * 3);
	unsigned char pad[3] = { 0, 0, 0 };

	// BMP writes from bottom to top
	int y = HEIGHT - 1;
	while (y >= 0)
	{
		int x = 0;
		while (x < WIDTH)
		{
			int word_index = y * WORDS_PR + (x / 16);
			int bit_index = 15 - (x % 16);

			unsigned char	pixel;
			if ((screen[word_index] >> bit_index) & 1)
				pixel = 0;
			else 
				pixel = 255;
			unsigned char	color[3] = { pixel, pixel, pixel }; // white is (255, 255, 255) and black is (0, 0, 0)
			fwrite(color, 1, 3, f);
			x++;
		}
		if (padding > 0)
			fwrite(pad, 1, padding, f);
		y--;
	}
	fclose(f);
}
