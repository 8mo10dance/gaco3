CC = gcc
CFLAGS = -std=c11 -g -static

9cc: 9cc.c
	$(CC) $(CFLAGS) 9cc.c -o 9cc

test: 9cc
	./test.sh

clean:
	rm -f 9cc *.o *~ tmp*

.PHONY: test clean
