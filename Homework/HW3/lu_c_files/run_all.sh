
#!/bin/bash
set -euo pipefail

# ============================================================
# Configuration
# ============================================================

EXEC="./par_factor"
LOG_FILE="lu_results_2x2.csv"

# Matrix column counts (m = n + 1)
N_VALUES=(256 512 1024 2048 4096 8192 16384)

# Processor grid configurations
PROCESSOR_GRIDS=(
    # "1 1"
    # "1 2"
    "2 2"
    # "2 4"
    # "4 2"
)

# ============================================================
# Initialize log file
# ============================================================

echo "m,n,P,Q,time,gflops" > "$LOG_FILE"

# ============================================================
# Run all configurations
# ============================================================

for n in "${N_VALUES[@]}"; do

    m=$((n + 1))

    for grid in "${PROCESSOR_GRIDS[@]}"; do

        read -r P Q <<< "$grid"

        NPROCS=$((P * Q))

        echo "=================================================="
        echo "Running m=$m, n=$n, P=$P, Q=$Q, processes=$NPROCS"
        echo "=================================================="

        OUTPUT=$(mpiexec -n "$NPROCS" "$EXEC" "$m" "$n" "$P" "$Q")

        RESULT=$(printf '%s\n' "$OUTPUT" | grep '^RESULT,')

        if [[ -z "$RESULT" ]]; then
            echo "ERROR: No RESULT line found."
            exit 1
        fi

        echo "${RESULT#RESULT,}" >> "$LOG_FILE"

        echo "$RESULT"
    done
done

echo "=================================================="
echo "All simulations complete."
echo "Results saved to: $LOG_FILE"
