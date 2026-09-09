CC = gcc 
CFLAGS = -O3 -march=native -std=c99 -Wall -Wextra
OBJS = bench.o mxm.o
bench: $(OBJS)
	$(CC) $(CFLAGS) -o bench $(OBJS)
clean:
	rm -f *.o bench 