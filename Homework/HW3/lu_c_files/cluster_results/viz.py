
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from pathlib import Path

# ============================================================
# File settings
# ============================================================

dataDirectory = Path("./Homework/HW3/lu_c_files/cluster_results")

unblocked_file = dataDirectory / "lu_results_unblocked.csv"
blocked_file = dataDirectory / "lu_results_block_11317540.csv"

BS_TARGET = 32

# ============================================================
# Load both datasets
# ============================================================

unblocked = pd.read_csv(unblocked_file)
blocked = pd.read_csv(blocked_file)

# Expected unblocked:
# m,n,P,Q,run,time,gflops

# Expected blocked:
# m,n,P,Q,bs,run,time,gflops

unblocked["nprocs"] = unblocked["P"] * unblocked["Q"]
blocked["nprocs"] = blocked["P"] * blocked["Q"]

print(f"Loaded {len(unblocked)} unblocked measurements.")
print(f"Loaded {len(blocked)} blocked measurements.")

print("Matrix sizes:", sorted(
    set(unblocked["n"]) | set(blocked["n"])
))
print("Processor counts:", sorted(
    set(unblocked["nprocs"]) | set(blocked["nprocs"])
))
print("Block sizes:", sorted(blocked["bs"].unique()))

# ============================================================
# Select block size
# ============================================================

blocked = blocked[blocked["bs"] == BS_TARGET].copy()

if blocked.empty:
    raise ValueError(f"No blocked data found for BS={BS_TARGET}")

# ============================================================
# Average repeated measurements
# ============================================================

# This averages repeated runs and processor-grid shapes
# with the same number of MPI processes.

avg_unblocked = (
    unblocked.groupby(["n", "nprocs"], as_index=False)
    .agg(gflops=("gflops", "mean"))
)

avg_blocked = (
    blocked.groupby(["n", "nprocs"], as_index=False)
    .agg(gflops=("gflops", "mean"))
)

# ============================================================
# Plot styling
# ============================================================

N_unique = np.sort(
    np.union1d(
        avg_unblocked["n"].unique(),
        avg_blocked["n"].unique()
    )
)

colors = plt.cm.viridis(
    np.linspace(0, 1, len(N_unique))
)

N_colors = {
    N: colors[i]
    for i, N in enumerate(N_unique)
}

# ============================================================
# Plot: GFLOPS vs MPI Processes
# ============================================================

fig, ax = plt.subplots(figsize=(11, 7))

for N in N_unique:

    # Unblocked LU
    subset = avg_unblocked[
        avg_unblocked["n"] == N
    ].sort_values("nprocs")

    if not subset.empty:
        ax.plot(
            subset["nprocs"],
            subset["gflops"],
            color=N_colors[N],
            linestyle="-",
            marker="o",
            linewidth=2,
            markersize=6
        )

    # Blocked LU
    subset = avg_blocked[
        avg_blocked["n"] == N
    ].sort_values("nprocs")

    if not subset.empty:
        ax.plot(
            subset["nprocs"],
            subset["gflops"],
            color=N_colors[N],
            linestyle="--",
            marker="s",
            linewidth=2,
            markersize=6
        )

# ============================================================
# Custom legends
# ============================================================

N_handles = [
    Line2D(
        [0], [0],
        color=N_colors[N],
        linewidth=2,
        label=f"N={N}"
    )
    for N in N_unique
]

method_handles = [
    Line2D(
        [0], [0],
        color="black",
        linestyle="-",
        marker="o",
        linewidth=2,
        label="Unblocked"
    ),
    Line2D(
        [0], [0],
        color="black",
        linestyle="--",
        marker="s",
        linewidth=2,
        label=f"Blocked (BS={BS_TARGET})"
    )
]

legend_N = ax.legend(
    handles=N_handles,
    title="Matrix Size",
    loc="upper left"
)

ax.add_artist(legend_N)

ax.legend(
    handles=method_handles,
    title="Method",
    loc="upper right"
)

# ============================================================
# Formatting
# ============================================================

ax.set_xlabel("Number of MPI Processes", fontsize=12)
ax.set_ylabel("Performance [GFLOPS]", fontsize=12)

ax.set_title(
    f"Parallel LU Factorization: GFLOPS vs Processors (BS={BS_TARGET})",
    fontsize=14
)

ax.set_xscale("log", base=2)

processor_counts = np.sort(
    np.union1d(
        unblocked["nprocs"].unique(),
        blocked["nprocs"].unique()
    )
)

ax.set_xticks(processor_counts)
ax.set_xticklabels(processor_counts)

ax.grid(True, alpha=0.3)

plt.tight_layout()

# ============================================================
# Save and display
# ============================================================

output_file = dataDirectory / "LU_GFLOPS_vs_Processors.pdf"

plt.savefig(output_file, bbox_inches="tight")

print(f"Saved plot to: {output_file}")

plt.show()
