
#!/bin/bash
set -euo pipefail

# ============================================================
# Configuration
# ============================================================

EXEC="./par_factor"
LOG_FILE="lu_results_unblocked.csv"

# Number of repetitions per configuration
NUM_RUNS=5

# Matrix sizes (m = n)
N_VALUES=(254 510 1022 2046)

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

echo "m,n,P,Q,run,time,gflops" > "$LOG_FILE"

# ============================================================
# Run all configurations
# ============================================================

for n in "${N_VALUES[@]}"; do

    m=$n

    for grid in "${PROCESSOR_GRIDS[@]}"; do

        read -r P Q <<< "$grid"

        NPROCS=$((P * Q))

        echo "=================================================="
        echo "Matrix: $m x $n"
        echo "Processor grid: $P x $Q"
        echo "MPI processes: $NPROCS"
        echo "Repetitions: $NUM_RUNS"
        echo "=================================================="

        for ((run=1; run<=NUM_RUNS; run++)); do

            echo "Running repetition $run / $NUM_RUNS"

            # Launch MPI job within SLURM allocation
            OUTPUT=$(srun --exact \
                --ntasks="$NPROCS" \
                --cpus-per-task=1 \
                "$EXEC" "$m" "$n" "$P" "$Q")

            # Extract machine-readable result
            RESULT=$(printf '%s\n' "$OUTPUT" | grep '^RESULT,')

            if [[ -z "$RESULT" ]]; then
                echo "ERROR: No RESULT line found."
                exit 1
            fi

            # Original result format:
            # RESULT,m,n,P,Q,time,gflops

            DATA="${RESULT#RESULT,}"

            # Split result into variables
            IFS=',' read -r rm rn rP rQ time gflops <<< "$DATA"

            # Save individual measurement
            echo "$rm,$rn,$rP,$rQ,$run,$time,$gflops" >> "$LOG_FILE"

            echo "Run $run: time=$time s, GFLOPS=$gflops"

        done

    done

done

echo "=================================================="
echo "All simulations complete."
echo "Results saved to: $LOG_FILE"
