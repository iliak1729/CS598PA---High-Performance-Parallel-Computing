#!/usr/bin/env bash
set -uo pipefail

# Run 3D Poisson JPCG for multiple global resolutions and MPI layouts.
# Usage: ./run_all.sh [path/to/jpcg_3D]

EXECUTABLE="${1:-./jpcg_3D}"
MPIEXEC="${MPIEXEC:-mpiexec}"
OUTDIR="${OUTDIR:-results/convergence}"
CSV="$OUTDIR/convergence.csv"
RAW_DIR="$OUTDIR/raw_logs"

# Global interior grid sizes (Nx = Ny = Nz = N).
RESOLUTIONS=(8 16 32 64 128 256 512 1024)

# Format: "ranks Px Py Pz". Product of Px,Py,Pz must equal ranks <= 8.
DECOMPOSITIONS=(
  "8 2 2 2"
)

if [[ ! -x "$EXECUTABLE" ]]; then
  echo "Error: executable '$EXECUTABLE' not found or not executable." >&2
  echo "Compile first: mpicc -O3 -Wall -Wextra -std=c11 -o jpcg_3D comm_mpi.c jpcg_3D.c -lm" >&2
  exit 1
fi

mkdir -p "$RAW_DIR"
printf 'N,Nx,Ny,Nz,h,ranks,Px,Py,Pz,iterations,relative_residual,rms_error,solve_time_s,status\n' > "$CSV"

failures=0
for N in "${RESOLUTIONS[@]}"; do
  h=$(awk -v n="$N" 'BEGIN {printf "%.15g", 1/(n+1)}')
  for layout in "${DECOMPOSITIONS[@]}"; do
    read -r ranks px py pz <<< "$layout"
    if (( ranks > 8 || px * py * pz != ranks || N < px || N < py || N < pz )); then
      echo "Skipping invalid layout: N=$N ranks=$ranks ($px,$py,$pz)" >&2
      continue
    fi

    name="N${N}_P${ranks}_${px}x${py}x${pz}"
    logfile="$RAW_DIR/${name}.log"
    echo "Running $name"

    if "$MPIEXEC" -n "$ranks" "$EXECUTABLE" "$N" "$N" "$N" "$px" "$py" "$pz" > "$logfile" 2>&1; then
      run_status=ok
    else
      run_status=failed
      failures=$((failures + 1))
    fi

    # Parse only the final summary, not the per-iteration output.
    iterations=$(awk '/^Iterations:/ {v=$2} END {print v}' "$logfile")
    residual=$(awk '/^Relative residual:/ {v=$3} END {print v}' "$logfile")
    error=$(awk '/^RMS error:/ {v=$3} END {print v}' "$logfile")
    runtime=$(awk '/^Solve time:/ {v=$3} END {print v}' "$logfile")

    if [[ -z "$iterations" || -z "$residual" || -z "$error" || -z "$runtime" || "$iterations" == "-1" ]]; then
      if [[ "$run_status" == ok ]]; then failures=$((failures + 1)); fi
      run_status=failed
    fi

    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
      "$N" "$N" "$N" "$N" "$h" "$ranks" "$px" "$py" "$pz" \
      "$iterations" "$residual" "$error" "$runtime" "$run_status" >> "$CSV"

    if [[ "$run_status" == ok ]]; then
      echo "  RMS error=$error, iterations=$iterations, time=${runtime}s"
    else
      echo "  FAILED; inspect $logfile" >&2
    fi
  done
done

echo
echo "Results: $CSV"
echo "Individual logs: $RAW_DIR/"
echo "Failed runs: $failures"
(( failures == 0 ))
