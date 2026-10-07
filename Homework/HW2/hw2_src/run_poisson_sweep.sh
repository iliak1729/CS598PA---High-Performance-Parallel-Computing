#!/bin/bash
trap 'echo "Benchmark interrupted."; exit 130' INT
# ============================================================
# Poisson strong-scaling benchmark sweep
#
# Nx = Ny = 4^k
# nx = ny = Nx - 1 = 4^k - 1
#
# Output:
#   timing.log
# ============================================================

# Values of k to test
K_VALUES=(3 4 5 6)

# Number of MPI ranks
P_VALUES=(1 2 4 8)
# METHODS 
METHODS=("dealer" "crystal")
# Number of benchmark repetitions per case
NRUNS=20

# Output file
OUTPUT="timing.log"


# ------------------------------------------------------------
# Start fresh
# ------------------------------------------------------------

rm -f "$OUTPUT"

echo "# Poisson parallel performance sweep" >> "$OUTPUT"
echo "# method Nx Ny P n n/P error total fst transpose comm divide GFLOPS" >> "$OUTPUT"
# ------------------------------------------------------------
# Sweep problem size
# ------------------------------------------------------------

for method in "${METHODS[@]}"; do

    for k in "${K_VALUES[@]}"; do

        Nx=$(( (4**k) / 2 ))
        Ny=$Nx

        for P in "${P_VALUES[@]}"; do

            echo "Running method=$method Nx=$Nx Ny=$Ny P=$P"

            mpiexec -n "$P" \
                ./bench_poisson "$Nx" "$Ny" "$NRUNS" "$method" \
                | grep -v '^#' \
                | grep -v '^$' \
                >> "$OUTPUT"

            echo "Completed method=$method Nx=$Nx Ny=$Ny P=$P"

        done
    done
done


echo
echo "Sweep complete."
echo "Results written to $OUTPUT"