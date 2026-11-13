
# ============================================================
# Compilers
# ============================================================
CC = gcc
MPICC = mpicc

CFLAGS = -O3 -Wall -Wextra -std=c11 -Iinclude
LDLIBS = -lm

# ============================================================
# Directories
# ============================================================
SRC_DIR = src
OBJ_DIR = obj
BIN_DIR = bin

# ============================================================
# Executables
# ============================================================
TARGET = $(BIN_DIR)/cg
PAR_TARGET = $(BIN_DIR)/parallel_3D
TEST_TARGET = $(BIN_DIR)/test_cg

# ============================================================
# Serial source and object files
# ============================================================
SRC = $(SRC_DIR)/ser_CG.c $(SRC_DIR)/cg.c
OBJ = $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRC))

# ============================================================
# Parallel 3D source and object files
# ============================================================
PAR_SRC = $(SRC_DIR)/poisson_3D_comm.c \
          $(SRC_DIR)/poisson_3D_par.c

PAR_OBJ = $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(PAR_SRC))

# ============================================================
# Default target
# ============================================================
.DEFAULT_GOAL := default

default: $(TARGET) $(PAR_TARGET)
	@printf "\n\033[0;32m[BUILD SUCCESSFUL]\033[0m\n"
	@printf "Serial executable:   %s\n" "$(TARGET)"
	@printf "Parallel executable: %s\n" "$(PAR_TARGET)"

all: $(TARGET) $(PAR_TARGET) test
	@printf "\n\033[0;32m[BUILD & TESTS SUCCESSFUL]\033[0m\n"

# ============================================================
# Serial CG executable
# ============================================================
$(TARGET): $(OBJ) | $(BIN_DIR)
	@printf "Linking %s...\n" "$@"
	@$(CC) $(OBJ) -o $@ $(LDLIBS)

# ============================================================
# Parallel 3D executable
# ============================================================
$(PAR_TARGET): $(PAR_OBJ) | $(BIN_DIR)
	@printf "Linking %s...\n" "$@"
	@$(MPICC) $(PAR_OBJ) -o $@ $(LDLIBS)

# ============================================================
# Compile serial source files
# ============================================================
$(OBJ_DIR)/ser_CG.o $(OBJ_DIR)/cg.o: $(OBJ_DIR)/%.o: $(SRC_DIR)/%.c include/cg.h | $(OBJ_DIR)
	@printf "Compiling %s...\n" "$<"
	@$(CC) $(CFLAGS) -c $< -o $@

# ============================================================
# Compile parallel 3D source files
# ============================================================
$(OBJ_DIR)/poisson_3D_comm.o: $(SRC_DIR)/poisson_3D_comm.c include/poisson_3D_comm.h | $(OBJ_DIR)
	@printf "Compiling MPI %s...\n" "$<"
	@$(MPICC) $(CFLAGS) -c $< -o $@

$(OBJ_DIR)/poisson_3D_par.o: $(SRC_DIR)/poisson_3D_par.c include/poisson_3D_par.h include/poisson_3D_comm.h | $(OBJ_DIR)
	@printf "Compiling MPI %s...\n" "$<"
	@$(MPICC) $(CFLAGS) -c $< -o $@

# ============================================================
# Compile other serial source files
# ============================================================
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c | $(OBJ_DIR)
	@printf "Compiling %s...\n" "$<"
	@$(CC) $(CFLAGS) -c $< -o $@

# ============================================================
# Create output directories
# ============================================================
$(OBJ_DIR) $(BIN_DIR):
	@mkdir -p $@

# ============================================================
# Tests
# ============================================================
$(TEST_TARGET): tests/test_cg.c $(OBJ_DIR)/cg.o $(OBJ_DIR)/poisson_1D.o $(OBJ_DIR)/poisson_2D.o $(OBJ_DIR)/poisson_3D.o $(OBJ_DIR)/vtk_writer.o | $(BIN_DIR)
	@printf "Compiling tests...\n"
	@$(CC) $(CFLAGS) $^ -o $@ $(LDLIBS)

test: $(TEST_TARGET)
	@printf "\nRunning tests...\n"
	@./$(TEST_TARGET)

# ============================================================
# Individual build targets
# ============================================================
serial: $(TARGET)
	@printf "\033[0;32m[SERIAL BUILD SUCCESSFUL]\033[0m\n"

parallel: $(PAR_TARGET)
	@printf "\033[0;32m[PARALLEL BUILD SUCCESSFUL]\033[0m\n"

# ============================================================
# Clean and rebuild
# ============================================================
clean:
	@printf "Cleaning build files...\n"
	@rm -rf $(OBJ_DIR) $(BIN_DIR)

rebuild:
	@$(MAKE) clean
	@$(MAKE) all

.PHONY: default all test serial parallel clean rebuild
