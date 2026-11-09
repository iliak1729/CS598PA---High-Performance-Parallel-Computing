
# Compiler
CC = gcc
CFLAGS = -O3 -Wall -Wextra -std=c11 -Iinclude
LDLIBS = -lm

# Directories
SRC_DIR = src
OBJ_DIR = obj
BIN_DIR = bin

# Executables
TARGET = $(BIN_DIR)/cg
TEST_TARGET = $(BIN_DIR)/test_cg

# Source and object files
SRC = $(SRC_DIR)/ser_CG.c $(SRC_DIR)/cg.c
OBJ = $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRC))

# Default target
.DEFAULT_GOAL := default

default: $(TARGET)
	@printf "\n\033[0;32m[BUILD SUCCESSFUL]\033[0m Main executable ready: %s\n" "$(TARGET)"

all: $(TARGET) test
	@printf "\n\033[0;32m[BUILD & TESTS SUCCESSFUL]\033[0m\n"

# Link main executable
$(TARGET): $(OBJ) | $(BIN_DIR)
	@printf "Linking %s...\n" "$@"
	@$(CC) $(OBJ) -o $@ $(LDLIBS)

# Compile source files
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c include/cg.h | $(OBJ_DIR)
	@printf "Compiling %s...\n" "$<"
	@$(CC) $(CFLAGS) -c $< -o $@

# Create output directories
$(OBJ_DIR) $(BIN_DIR):
	@mkdir -p $@

# ===============================
# Tests
# ===============================
$(TEST_TARGET): tests/test_cg.c $(OBJ_DIR)/cg.o $(OBJ_DIR)/poisson_1D.o $(OBJ_DIR)/poisson_2D.o $(OBJ_DIR)/vtk_writer.o | $(BIN_DIR)
	@printf "Compiling tests...\n"
	@$(CC) $(CFLAGS) $^ -o $@ $(LDLIBS)

test: $(TEST_TARGET)
	@printf "\nRunning tests...\n"
	@./$(TEST_TARGET)

# Remove compiled files
clean:
	@printf "Cleaning build files...\n"
	@rm -rf $(OBJ_DIR) $(BIN_DIR)

# Rebuild everything
rebuild:
	@$(MAKE) clean
	@$(MAKE) all

.PHONY: default all test clean rebuild
