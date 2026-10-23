#!/usr/bin/env bash
set -euo pipefail

# Optional positional arguments: TL TR alpha L
if (( $# > 4 )); then
    echo "Usage: $0 [TL] [TR] [alpha] [L]" >&2
    exit 1
fi
TL=${1:-1.0}
TR=${2:-1.0}
alpha=${3:-1.0}
L=${4:-1.0}

# Edit these settings to configure the sweep.
EXE=${EXE:-./par_tridiag}
N_VALUES=(31 63 127 255 511 1023 2047 4095 8191 16383)
NPROC_VALUES=(8)
REPS=${REPS:-20}
OUTPUT_TEMPERATURE=${OUTPUT_TEMPERATURE:-0}  # 1: save one temperature file per N/P; 0: no files
OUTDIR=${OUTDIR:-timing_results}

if (( REPS < 1 )); then
    echo "REPS must be >= 1" >&2
    exit 1
fi
if [[ "$OUTPUT_TEMPERATURE" != 0 && "$OUTPUT_TEMPERATURE" != 1 ]]; then
    echo "OUTPUT_TEMPERATURE must be 0 or 1" >&2
    exit 1
fi

mkdir -p "$OUTDIR"
RESULTS="$OUTDIR/convergence.txt"
printf '# N nproc dx L2_error Avg_Solver_Time\n' > "$RESULTS"

for N in "${N_VALUES[@]}"; do
    for nproc in "${NPROC_VALUES[@]}"; do
        echo "Running N=$N with $nproc MPI ranks ($REPS repetitions)"
        sum_time=0
        l2_error=nan

        for ((rep=1; rep<=REPS; rep++)); do
            logfile="$OUTDIR/run_N${N}_P${nproc}_rep${rep}.log"

            # Requires the C solver to honor WRITE_TEMPERATURE (see instructions).
            # Only the first repetition writes the temperature file when enabled.
            write_this_rep=0
            if (( OUTPUT_TEMPERATURE == 1 && rep == 1 )); then
                write_this_rep=1
            fi

            WRITE_TEMPERATURE="$write_this_rep" mpirun -np "$nproc" "$EXE" \
                "$L" "$N" "$TL" "$TR" "$alpha" > "$logfile"

            solver_time=$(awk '$1 == "SOLVER_TIME" {print $2; exit}' "$logfile")
            if [[ -z "$solver_time" ]]; then
                echo "Missing SOLVER_TIME in $logfile" >&2
                exit 1
            fi
            sum_time=$(awk -v s="$sum_time" -v t="$solver_time" 'BEGIN {printf "%.17g", s+t}')

            if (( write_this_rep == 1 )); then
                if [[ ! -f Temperature.txt ]]; then
                    echo "Temperature.txt missing for N=$N, P=$nproc" >&2
                    exit 1
                fi
                tempfile="$OUTDIR/TemperatureFile${N}_P${nproc}.txt"
                cp Temperature.txt "$tempfile"
                l2_error=$(awk -v N="$N" -v L="$L" '
                    /^[[:space:]]*#/ || NF == 0 {next}
                    {sumsq += $6*$6; count++}
                    END {
                        if (count != N) {
                            printf "Expected %d rows, got %d\n", N, count > "/dev/stderr"
                            exit 1
                        }
                        printf "%.16e", sqrt(L/(N+1)*sumsq)
                    }
                ' "$tempfile")
            fi
        done

        avg_time=$(awk -v s="$sum_time" -v r="$REPS" 'BEGIN {printf "%.16e", s/r}')
        dx=$(awk -v L="$L" -v N="$N" 'BEGIN {printf "%.16e", L/(N+1)}')
        printf '%d %d %s %s %s\n' "$N" "$nproc" "$dx" "$l2_error" "$avg_time" | tee -a "$RESULTS"
    done
done

echo "Finished. Results: $RESULTS"