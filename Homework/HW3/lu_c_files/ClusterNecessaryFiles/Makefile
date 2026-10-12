
# ============================================================
# Compiler Configuration
# ============================================================

MPICC = mpicc

CFLAGS = -O3 -march=native -std=c11 -Wall -Wextra

# ============================================================
# Detect CPU Vendor
# ============================================================

CPU_VENDOR := $(shell lscpu | grep 'Vendor ID:' | awk '{print $$3}')

# Allow manual override:
# make BLAS=blis
# make BLAS=mkl
# make BLAS=openblas

ifeq ($(CPU_VENDOR),AuthenticAMD)
    DEFAULT_BLAS = blis
else ifeq ($(CPU_VENDOR),GenuineIntel)
    DEFAULT_BLAS = mkl
else
    DEFAULT_BLAS = openblas
endif

BLAS ?= $(DEFAULT_BLAS)

# ============================================================
# BLAS Configuration
# ============================================================

ifeq ($(BLAS),blis)
    BLAS_LIBS = -lblis
else ifeq ($(BLAS),mkl)
    BLAS_LIBS = -lmkl_rt -lpthread -ldl
else ifeq ($(BLAS),openblas)
    BLAS_LIBS = -lopenblas 
else
    $(error Unknown BLAS library: $(BLAS))
endif

# ============================================================
# Build Targets
# ============================================================

.PHONY: all clean info

all: par_factor par_factor_block

# ------------------------------------------------------------
# Unblocked Parallel LU
# ------------------------------------------------------------

par_factor: par_factor.o msg_mpi.o
	$(MPICC) $(CFLAGS) $^ -o $@ -lm

par_factor.o: par_factor.c msg.h
	$(MPICC) $(CFLAGS) -c $< -o $@

# ------------------------------------------------------------
# Blocked Parallel LU
# ------------------------------------------------------------

par_factor_block: par_factor_block.o msg_mpi.o
	$(MPICC) $(CFLAGS) $^ -o $@ $(BLAS_LIBS) -lm

par_factor_block.o: par_factor_block.c msg.h
	$(MPICC) $(CFLAGS) -c $< -o $@

# ------------------------------------------------------------
# MPI Communication
# ------------------------------------------------------------

msg_mpi.o: msg_mpi.c msg.h
	$(MPICC) $(CFLAGS) -c $< -o $@

# ============================================================
# Information
# ============================================================

info:
	@echo "CPU Vendor:   $(CPU_VENDOR)"
	@echo "BLAS Library: $(BLAS)"
	@echo "MPI Compiler: $(MPICC)"

# ============================================================
# Cleanup
# ============================================================

clean:
	rm -f *.o par_factor par_factor_block
