#!/bin/bash

P_VALUES=(1 2 4 8)

for P in "${P_VALUES[@]}"; do

    OUTPUT="timing_P${P}.log"

    echo "# Poisson parallel performance sweep" > "$OUTPUT"
    echo "# method Nx Ny P n n/P error total fst transpose comm divide GFLOPS" >> "$OUTPUT"

    echo "Submitting P=$P"

    sbatch \
        --ntasks="$P" \
        --ntasks-per-node="$P" \
        --output="poisson_P${P}.log" \
        poisson.sbatch "$P" "$OUTPUT"

done