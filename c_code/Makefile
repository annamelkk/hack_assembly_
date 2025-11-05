CC = gcc
CFLAGS = -Wall -Wextra -Werror
TARGET = draw_test

SRCS = main.c draw.c
OBJS = $(SRCS:.c=.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS)

%.o: %.c draw.h
	$(CC) $(CFLAGS) -c $< -o $@

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(OBJS) $(TARGET) output.bmp

.PHONY: all clean run
