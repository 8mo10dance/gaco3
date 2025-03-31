GUILE_VER = guile-3.0

CC = gcc
CFLAGS = $(shell pkg-config --cflags $(GUILE_VER))
LDFLAGS = $(shell pkg-config --libs $(GUILE_VER))

.PHONY: all clean

all: build

build: main.c
	$(CC) -o app main.c $(CFLAGS) $(LDFLAGS)

clean:
	rm -f app
