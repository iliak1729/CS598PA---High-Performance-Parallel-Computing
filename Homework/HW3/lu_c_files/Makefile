# Hand-coded version: Homebrew GCC
CC = /opt/homebrew/bin/gcc-15

# Apple Accelerate version: Apple Clang
ACCEL_CC = /usr/bin/clang

CFLAGS = -O3 -march=native -std=c11 -Wall -Wextra
ACCEL_CFLAGS = -O3 -march=native -std=c11 -Wall -Wextra \
               -DACCELERATE_NEW_LAPACK

all: factor factor_blas par_factor par_factor_block

# ------------------------------------------------------------
# Hand-coded matrix multiply
# ------------------------------------------------------------

factor: factor.o
	$(CC) $(CFLAGS) factor.o -o factor -lm

factor.o: factor.c
	$(CC) $(CFLAGS) -c factor.c -o factor.o

# ------------------------------------------------------------
# Apple Accelerate cblas_dgemm
# ------------------------------------------------------------

factor_blas: factor_blas.o
	$(ACCEL_CC) $(ACCEL_CFLAGS) factor_blas.o -o factor_blas \
	    -framework Accelerate -lm

factor_blas.o: factor_blas.c
	$(ACCEL_CC) $(ACCEL_CFLAGS) -c factor_blas.c -o factor_blas.o


# ------------------------------------------------------------
# Parallel MPI version
# ------------------------------------------------------------

MPICC = env OMPI_CC=/usr/bin/clang mpicc

MPI_CFLAGS = -O3 -march=native -std=c11 -Wall -Wextra \
             -DACCELERATE_NEW_LAPACK

par_factor: par_factor.o msg_mpi.o
	$(MPICC) $(MPI_CFLAGS) par_factor.o msg_mpi.o \
	    -o par_factor -framework Accelerate -lm

par_factor.o: par_factor.c
	$(MPICC) $(MPI_CFLAGS) -c par_factor.c -o par_factor.o

msg_mpi.o: msg_mpi.c
	$(MPICC) $(MPI_CFLAGS) -c msg_mpi.c -o msg_mpi.o

# ------------------------------------------------------------
# Parallel MPI version with Block
# ------------------------------------------------------------

par_factor_block: par_factor_block.o msg_mpi.o
	$(MPICC) $(MPI_CFLAGS) par_factor_block.o msg_mpi.o \
	    -o par_factor_block -framework Accelerate -lm

par_factor_block.o: par_factor_block.c
	$(MPICC) $(MPI_CFLAGS) -c par_factor_block.c -o par_factor_block.o
# ------------------------------------------------------------

clean:
	rm -f factor factor_blas par_factor par_factor_block *.o
