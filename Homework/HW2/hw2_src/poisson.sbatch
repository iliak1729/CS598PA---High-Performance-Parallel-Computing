#!/bin/bash

#SBATCH --account=26fa-cs598pa-eng
#SBATCH --partition=eng-instruction
#SBATCH --time=00:10:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --job-name=poisson

module load openmpi

P=$1
OUTPUT=$2

K_VALUES=(3 4 5 6)
METHODS=("dealer" "crystal")
NRUNS=20

echo "Running Poisson sweep with P=$P"

for method in "${METHODS[@]}"; do

    for k in "${K_VALUES[@]}"; do

        Nx=$(( (4**k) / 2 ))
        Ny=$Nx

        echo "Running method=$method Nx=$Nx Ny=$Ny P=$P"

        mpirun -np "$P" \
            --bind-to core \
            ./bench_poisson "$Nx" "$Ny" "$NRUNS" "$method" \
            | grep -v '^#' \
            | grep -v '^$' \
            >> "$OUTPUT"

        echo "Completed method=$method Nx=$Nx Ny=$Ny P=$P"

    done

done