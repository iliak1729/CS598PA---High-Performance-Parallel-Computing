
#!/bin/bash
set -euo pipefail

# ============================================================
# Configuration
# ============================================================

EXEC="./par_factor_block"
LOG_FILE="lu_results_block_2x2.csv"

# Matrix column counts (m = n + 1)
N_VALUES=(255 511 1023 2047)

# Block sizes
BLOCK_SIZES=(4 8 16 32 64 128 256)

# Processor grid configurations
PROCESSOR_GRIDS=(
    "1 1"
    "1 2"
    "2 2"
    "2 4"
    "4 2"
)

# ============================================================
# Initialize log file
# ============================================================

echo "m,n,P,Q,time,gflops,bs" > "$LOG_FILE"

# ============================================================
# Run all configurations
# ============================================================

for n in "${N_VALUES[@]}"; do

    m=$((n))

    for grid in "${PROCESSOR_GRIDS[@]}"; do

        read -r P Q <<< "$grid"

        NPROCS=$((P * Q))

        for bs in "${BLOCK_SIZES[@]}"; do

            echo "=================================================="
            echo "Running m=$m, n=$n, P=$P, Q=$Q, bs=$bs, processes=$NPROCS"
            echo "=================================================="

            OUTPUT=$(mpiexec -n "$NPROCS" "$EXEC" \
                "$m" "$n" "$P" "$Q" "$bs")

            RESULT=$(printf '%s\n' "$OUTPUT" | grep '^RESULT,' || true)

            if [[ -z "$RESULT" ]]; then
                echo "ERROR: No RESULT line found."
                exit 1
            fi

            echo "${RESULT#RESULT,}" >> "$LOG_FILE"

            echo "$RESULT"

        done
    done
done

echo "=================================================="
echo "All simulations complete."
echo "Results saved to: $LOG_FILE"
