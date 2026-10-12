
#!/bin/bash
set -euo pipefail

# ============================================================
# Configuration
# ============================================================

EXEC="./par_factor_block"
LOG_FILE="lu_results_block_${SLURM_JOB_ID:-local}.csv"

# Number of repetitions per configuration
NUM_RUNS=5

# Matrix sizes (m = n)
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

echo "m,n,P,Q,bs,run,time,gflops" > "$LOG_FILE"

# ============================================================
# Run all configurations
# ============================================================

for n in "${N_VALUES[@]}"; do

    m=$n

    for grid in "${PROCESSOR_GRIDS[@]}"; do

        read -r P Q <<< "$grid"

        NPROCS=$((P * Q))

        for bs in "${BLOCK_SIZES[@]}"; do

            echo "=================================================="
            echo "Matrix: $m x $n"
            echo "Processor grid: $P x $Q"
            echo "MPI processes: $NPROCS"
            echo "Block size: $bs"
            echo "Repetitions: $NUM_RUNS"
            echo "=================================================="

            for ((run=1; run<=NUM_RUNS; run++)); do

                echo "Running repetition $run / $NUM_RUNS"

                # Launch MPI job within SLURM allocation
                OUTPUT=$(srun --exact \
                    --ntasks="$NPROCS" \
                    --cpus-per-task=1 \
                    "$EXEC" "$m" "$n" "$P" "$Q" "$bs")

                # Extract machine-readable result
                RESULT=$(printf '%s\n' "$OUTPUT" | grep '^RESULT,' || true)

                if [[ -z "$RESULT" ]]; then
                    echo "ERROR: No RESULT line found."
                    exit 1
                fi

                # Original C output format:
                # RESULT,m,n,P,Q,time,gflops,bs

                DATA="${RESULT#RESULT,}"

                # Extract individual fields
                IFS=',' read -r rm rn rP rQ time gflops rbs <<< "$DATA"

                # Save individual measurement
                echo "$rm,$rn,$rP,$rQ,$rbs,$run,$time,$gflops" >> "$LOG_FILE"

                echo "Run $run: time=$time s, GFLOPS=$gflops"

            done

        done

    done

done

echo "=================================================="
echo "All simulations complete."
echo "Results saved to: $LOG_FILE"
