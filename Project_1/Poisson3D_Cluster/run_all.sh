#!/usr/bin/env bash
set -uo pipefail

# Usage: ./run_all_parallel_3D.sh [path/to/parallel_3D]
# Override e.g.: RESOLUTIONS="8 16 32 64 128" MPIEXEC=mpirun ./run_all_parallel_3D.sh
EXECUTABLE="${1:-./bin/parallel_3D}"
MPIEXEC="${MPIEXEC:-mpiexec}"
OUTDIR="${OUTDIR:-results/parallel_3D}"
RESOLUTIONS="${RESOLUTIONS:-8 16 32 64 128}"
CSV="$OUTDIR/convergence.csv"
RAW_DIR="$OUTDIR/raw_logs"

# Each layout is: ranks Px Py Pz (maximum eight ranks)
DECOMPOSITIONS=(
  '1 1 1 1'
  '2 2 1 1'
  '4 2 2 1'
  '8 2 2 2'
  '8 4 2 1'
)

if [[ ! -x "$EXECUTABLE" ]]; then
  echo "Executable not found: $EXECUTABLE" >&2
  echo 'Build it with: make parallel' >&2
  exit 1
fi
mkdir -p "$RAW_DIR"
printf 'N,Nx,Ny,Nz,h,ranks,Px,Py,Pz,iterations,relative_residual,rms_error,solve_time_s,status\n' > "$CSV"

failures=0
for N in $RESOLUTIONS; do
  if ! [[ "$N" =~ ^[0-9]+$ ]] || (( N < 1 )); then
    echo "Invalid resolution: $N" >&2; exit 1
  fi
  h=$(awk -v n="$N" 'BEGIN {printf "%.15g", 1/(n+1)}')
  for layout in "${DECOMPOSITIONS[@]}"; do
    read -r ranks px py pz <<< "$layout"
    if (( ranks > 8 || px*py*pz != ranks || N < px || N < py || N < pz )); then
      echo "Skipping N=$N, layout=$layout"; continue
    fi
    name="N${N}_P${ranks}_${px}x${py}x${pz}"
    logfile="$RAW_DIR/$name.log"
    echo "Running $name"

    if "$MPIEXEC" -n "$ranks" "$EXECUTABLE" "$N" "$N" "$N" "$px" "$py" "$pz" > "$logfile" 2>&1; then
      status=ok
    else
      status=failed
    fi

    # Matches the original program's rank-zero summary labels.
    iterations=$(awk '/^[[:space:]]*Iterations[[:space:]]*:/ {v=$2} END {print v}' "$logfile")
    residual=$(awk '/^[[:space:]]*Relative residual[[:space:]]*:/ {v=$3} END {print v}' "$logfile")
    error=$(awk '/^[[:space:]]*RMS error[[:space:]]*:/ {v=$3} END {print v}' "$logfile")
    runtime=$(awk '/^[[:space:]]*Solve time[[:space:]]*:/ {v=$3} END {print v}' "$logfile")

    if [[ ! "$iterations" =~ ^[0-9]+$ || ! "$residual" =~ ^[+-]?[0-9.eE+-]+$ || ! "$error" =~ ^[+-]?[0-9.eE+-]+$ || ! "$runtime" =~ ^[+-]?[0-9.eE+-]+$ ]]; then
      status=failed
    fi
    [[ "$status" == ok ]] || failures=$((failures+1))

    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
      "$N" "$N" "$N" "$N" "$h" "$ranks" "$px" "$py" "$pz" \
      "$iterations" "$residual" "$error" "$runtime" "$status" >> "$CSV"

    if [[ "$status" == ok ]]; then
      echo "  RMS error=$error, iterations=$iterations, time=${runtime}s"
    else
      echo "  FAILED or output labels not recognized; see $logfile" >&2
    fi
  done
done
printf '\nCSV: %s\nRaw logs: %s\nFailed runs: %d\n' "$CSV" "$RAW_DIR" "$failures"
(( failures == 0 ))
