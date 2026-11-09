# Parallel tridiagonal solver -- OpenMPI / macOS Apple Silicon
# Homebrew OpenMPI normally provides mpifort in /opt/homebrew/bin.
# Override on the command line if desired, e.g. make MPIFC=mpif77

MPIFC ?= mpifort

FFLAGS ?= -O3 -fdefault-real-8 -fdefault-double-8 -std=legacy -ffixed-line-length-none
DBGFLAGS = -O0 -g -fdefault-real-8 -fdefault-double-8 -std=legacy -ffixed-line-length-none \
           -fcheck=all -fbacktrace -Wall -Wextra




OBJS = jpcg.o comm_mpi.o

.PHONY: all clean debug run

all: jpcg

jpcg: $(OBJS)
	$(MPIFC) $(FFLAGS) $(OBJS) -o $@

jpcg.o: jpcg.f TOTAL
	$(MPIFC) $(FFLAGS) -c jpcg.f

comm_mpi.o: comm_mpi.f TOTAL
	$(MPIFC) $(FFLAGS) -c comm_mpi.f

debug: clean
	$(MAKE) FFLAGS="$(DBGFLAGS)" jpcg

# README example: P=4, n=5 -> 23 unknowns.
run: jpcg
	mpirun -np 4 ./jpcg 5

clean:
	rm -f *.o *.mod jpcg
