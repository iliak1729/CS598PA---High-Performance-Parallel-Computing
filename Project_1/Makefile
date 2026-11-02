
# Compiler
CC = gcc

# Compiler flags
CFLAGS = -O3 -Wall -Wextra -std=c11 -Iinclude

# Libraries
LDLIBS = -lm

# Directories
SRC_DIR = src
OBJ_DIR = obj
BIN_DIR = bin

# Executable
TARGET = $(BIN_DIR)/cg

# Source and object files
SRC = $(SRC_DIR)/ser_CG.c $(SRC_DIR)/cg.c
OBJ = $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRC))

# Default target
all: $(TARGET)

# Link executable
$(TARGET): $(OBJ) | $(BIN_DIR)
	$(CC) $(OBJ) -o $@ $(LDLIBS)

# Compile source files
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c include/cg.h | $(OBJ_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Create output directories
$(OBJ_DIR) $(BIN_DIR):
	mkdir -p $@

# Remove compiled files
clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)

# Rebuild everything
rebuild:
	$(MAKE) clean
	$(MAKE) all

.PHONY: all clean rebuild
