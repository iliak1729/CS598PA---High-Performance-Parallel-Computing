#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Configuration
# ============================================================

EXEC="./par_tridiag"
LOG_FILE="convergence.csv"

# Solver parameters: L N TL TR alpha
TL=${1:-1.0}
TR=${2:-1.0}
alpha=${3:-1.0}
L=${4:-1.0}

# Number of interior unknowns (N), not N+1
# 
N_VALUES=(31 63 127 255 511 1023 2047 4095 8191 16383 32767 65535 131071 262143 524287 1048575)

# MPI process counts
NPROC_VALUES=(1 2 4 8)

# Number of independent runs per (N, nproc)
REPS=20

# 1: save Temperature.txt and calculate L2 error; 0: timing only
OUTPUT_TEMPERATURE=0

# ============================================================
# Initialize log file
# ============================================================

printf 'N,nproc,dx,L2_error,avg_solver_time\n' > "$LOG_FILE"

# ============================================================
# Run all configurations
# ============================================================
for N in "${N_VALUES[@]}"; do

    for nproc in "${NPROC_VALUES[@]}"; do

        sum_time=0

        for ((rep=1; rep<=REPS; rep++)); do

            OUTPUT=$(mpiexec -n "$nproc" "$EXEC" \
                "$L" "$N" "$TL" "$TR" "$alpha")

            # Find the RESULT line
            RESULT=$(printf '%s\n' "$OUTPUT" | grep '^RESULT,')

            if [[ -z "$RESULT" ]]; then
                echo "ERROR: No RESULT line found."
                exit 1
            fi

            # Extract fields
            IFS=',' read -r prefix result_N result_nproc \
                dx L2_error solver_time <<< "$RESULT"

            # Accumulate solver time
            sum_time=$(awk -v sum="$sum_time" -v t="$solver_time" \
                'BEGIN {printf "%.16e", sum+t}')

        done

        # Calculate average execution time
        avg_time=$(awk -v sum="$sum_time" -v reps="$REPS" \
            'BEGIN {printf "%.16e", sum/reps}')

        # Save one result per configuration
        echo "$N,$nproc,$dx,$L2_error,$avg_time" >> "$LOG_FILE"

    done
done

echo "=================================================="
echo "All simulations complete."
echo "Results saved to: $LOG_FILE"
