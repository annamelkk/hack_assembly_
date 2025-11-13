# Hack Assembly Horizontal Line Drawer

This project demonstrates how to draw a **horizontal line** on the [Hack computer](https://www.nand2tetris.org/) screen using both **Hack assembly** and **C**.  
It includes low-level bitwise address computations and pixel manipulation in simulated screen memory.

---

## Overview

The Hack computer’s display is a **bitmap** memory region starting at address **16384 (`SCREEN`)**.  
Each word (16 bits) represents **16 horizontal pixels**, and the screen is **512×256 pixels**, meaning each row has **32 words**.

This project draws a horizontal line from coordinates `(x1, y)` to `(x2, y)` by:

1. Computing the **start** and **end word addresses** for a given row.
2. Generating bit masks to fill pixels between `x1` and `x2`.
3. Writing to the Hack’s screen memory directly.

You’ll find both:
- `/assembly_code` → Hack assembly version  
- `/c_code` → equivalent C implementation for clarity and testing

---

## Core Formula

Each pixel is stored in memory at:

$$\text{address} = \text{SCREEN} + 32 * y + (x / 16)$$
$$\text{bit} = x \  \text{mod}  \ 16$$
### Registers Used (Assembly)

| Register | Purpose                               |
| -------- | ------------------------------------- |
| `R0`     | y-coordinate                          |
| `R1`     | x1 (becomes x1 mod 16 after division) |
| `R2`     | x2 (becomes x2 mod 16 after division) |
| `R3`     | color (1 = white, 0 = black)          |
| `R4`     | start word address                    |
| `R5`     | end word address                      |
| `R6`     | current address (loop counter)        |
| `R7`     | temporary register (bit mask)         |
| `R8`     | x1 / 16                               |
| `R9`     | x2 / 16                               |
| `R10`    | constant 16                           |

---

##  How It Works

1. Multiply `y` by 32 to get the row offset.
2. Divide `x1` and `x2` by 16 to find the start and end words.
3. Add `SCREEN` base address to get absolute memory addresses.
4. Fill bits between `x1` and `x2` using `set_pixel()` function.

## Hack Assembly Implementation

The Hack Assembly implementation should be tested inside the Nand2Tetris CPU emulator.

Version 1 contains more optimized however not memory saving approach, and Version 2 uses less registers, however speed is compromised.

The corresponding registers for x1, x2, y and color (1 for black, 0 for white) should be set.


## C Implementation

The C version emulates Hack screen memory in an array and applies the same bitwise logic:

```c
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
```


To test the C version simply compile the project:

```bash
make #compile the project

./draw_test #run the program

display output.bmp #display the result
```


## Tools Used

- [Nand2Tetris Hack Computer](https://www.nand2tetris.org/)
- [CPU Emulator](https://nand2tetris.github.io/web-ide/cpu)
- GCC for the C version
