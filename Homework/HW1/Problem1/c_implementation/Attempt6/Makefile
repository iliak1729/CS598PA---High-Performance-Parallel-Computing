CC = clang

CFLAGS = -O3 \
         -ffast-math \
         -march=native \
         -funroll-loops \
         -flto \
         -std=c99 \
         -Wall \
         -Wextra

OBJS = bench.o mxm.o

bench: $(OBJS)
	$(CC) $(CFLAGS) -o bench $(OBJS)

clean:
	rm -f *.o bench