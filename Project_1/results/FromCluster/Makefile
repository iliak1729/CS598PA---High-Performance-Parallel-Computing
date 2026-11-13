CC = mpicc
CFLAGS = -O3 -Wall -Wextra -std=c11 -Iinclude
LDLIBS = -lm

SRC = src/poisson_3D_comm.c src/poisson_3D_par.c
OBJ = $(SRC:src/%.c=obj/%.o)

TARGET = bin/parallel_3D

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJ)
	@mkdir -p bin
	$(CC) $(OBJ) -o $@ $(LDLIBS)

obj/%.o: src/%.c
	@mkdir -p obj
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf obj bin
