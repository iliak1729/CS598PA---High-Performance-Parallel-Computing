
#!/usr/bin/env bash
set -euo pipefail

# if (( $# != 4 )); then
#     echo "Usage: $0 TL TR alpha L" >&2
#     exit 1
# fi

TL=${1:-1.0}
TR=${2:-1.0}
alpha=${3:-1.0}
L=${4:-1.0}

# Configuration
EXE="${EXE:-./par_tridiag}"
NPROCS="${NPROCS:-4}"
n_VALUES=(32 64 128 256 512 1024)

printf '# N dx L2_error\n' > convergence.txt

for n in "${n_VALUES[@]}"; do
    N=$((n - 1))
    echo "Running N=$N with $NPROCS MPI ranks"

    # Solver arguments: L N TL TR alpha
    mpirun -np "$NPROCS" "$EXE" \
        "$L" "$N" "$TL" "$TR" "$alpha" > "run_N${N}.log"

    if [[ ! -f Temperature.txt ]]; then
        echo "Error: Temperature.txt was not produced for N=$N" >&2
        exit 1
    fi

    cp Temperature.txt "TemperatureFile${N}.txt"

    awk -v N="$N" -v L="$L" '
        BEGIN { sumsq = 0; count = 0 }
        /^[[:space:]]*#/ || NF == 0 { next }
        {
            error = $6
            sumsq += error * error
            count++
        }
        END {
            if (count != N) {
                printf "Expected %d rows, found %d\n", N, count > "/dev/stderr"
                exit 1
            }
            dx = L / (N + 1)
            printf "%d %.16e %.16e\n",
                   N, dx, sqrt(dx * sumsq)
        }
    ' "TemperatureFile${N}.txt" | tee -a convergence.txt
done

echo "Finished. Convergence data: convergence.txt"
