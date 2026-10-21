import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
# ============================================================
# Load data
# ============================================================

dataDirectory = "./Homework/HW3/lu_c_files/cluster_results/"

unblocked_file = dataDirectory + "lu_results_unblocked.csv"
blocked_file = dataDirectory + "lu_results_block_11317540.csv"

unblocked = pd.read_csv(unblocked_file)
blocked = pd.read_csv(blocked_file)

# ============================================================
# Unblocked LU data
# Columns: m,n,P,Q,run,time,gflops
# ============================================================

m_unblocked      = unblocked["m"].to_numpy(dtype=int)
n_unblocked      = unblocked["n"].to_numpy(dtype=int)
P_unblocked      = unblocked["P"].to_numpy(dtype=int)
Q_unblocked      = unblocked["Q"].to_numpy(dtype=int)
run_unblocked    = unblocked["run"].to_numpy(dtype=int)
time_unblocked   = unblocked["time"].to_numpy(dtype=float)
gflops_unblocked = unblocked["gflops"].to_numpy(dtype=float)

# Total MPI processes
nprocs_unblocked = P_unblocked * Q_unblocked

# ============================================================
# Blocked LU data
# Columns: m,n,P,Q,bs,run,time,gflops
# ============================================================

m_blocked      = blocked["m"].to_numpy(dtype=int)
n_blocked      = blocked["n"].to_numpy(dtype=int)
P_blocked      = blocked["P"].to_numpy(dtype=int)
Q_blocked      = blocked["Q"].to_numpy(dtype=int)
bs_blocked     = blocked["bs"].to_numpy(dtype=int)
run_blocked    = blocked["run"].to_numpy(dtype=int)
time_blocked   = blocked["time"].to_numpy(dtype=float)
gflops_blocked = blocked["gflops"].to_numpy(dtype=float)

# Total MPI processes
nprocs_blocked = P_blocked * Q_blocked

# ============================================================
# Print loaded data information
# ============================================================

print(f"Loaded {len(m_unblocked)} unblocked measurements.")
print(f"Loaded {len(m_blocked)} blocked measurements.")

print("\nUnblocked:")
print("Matrix sizes:", np.unique(n_unblocked))
print("Processor counts:", np.unique(nprocs_unblocked))

print("\nBlocked:")
print("Matrix sizes:", np.unique(n_blocked))
print("Processor counts:", np.unique(nprocs_blocked))
print("Block sizes:", np.unique(bs_blocked))


# ============================================================
# Plot 9: Unblocked LU - GFLOPS vs N
# Comparison of 2x4 and 4x2 Processor Grids
# ============================================================

# ------------------------------------------------------------
# Plot settings
# ------------------------------------------------------------

processor_grids = [(2, 4), (4, 2)]

colors = plt.cm.viridis(
    np.linspace(0, 1, len(processor_grids))
)

fig, ax = plt.subplots(figsize=(10, 6))

# ------------------------------------------------------------
# Loop over processor grids
# ------------------------------------------------------------

for i, (P_target, Q_target) in enumerate(processor_grids):

    mask_grid = (
        (P_unblocked == P_target) &
        (Q_unblocked == Q_target)
    )

    N_unique = np.sort(np.unique(n_unblocked[mask_grid]))

    x_values = []
    gflops_values = []

    # Calculate average GFLOPS for each matrix size
    for N in N_unique:

        mask = (
            (n_unblocked == N) &
            (P_unblocked == P_target) &
            (Q_unblocked == Q_target)
        )

        avg_gflops = np.mean(gflops_unblocked[mask])

        x_values.append(N)
        gflops_values.append(avg_gflops)

    if len(x_values) == 0:
        continue

    # Plot curve for this processor grid
    ax.plot(
        x_values,
        gflops_values,
        marker="o",
        linestyle="-",
        linewidth=2,
        markersize=6,
        color=colors[i],
        label=f"{P_target} x {Q_target}"
    )

# ------------------------------------------------------------
# Formatting
# ------------------------------------------------------------

ax.set_xlabel("Matrix Size N")
ax.set_ylabel("Performance [GFLOPS]")

ax.set_title(
    "Unblocked LU: GFLOPS vs N for Different Processor Grids"
)

ax.set_xscale("log", base=2)

N_all = np.sort(np.unique(n_unblocked))
ax.set_xticks(N_all)
ax.set_xticklabels(N_all)

ax.grid(True, alpha=0.3)
ax.legend(title="Processor Grid")

plt.tight_layout()

# ------------------------------------------------------------
# Save and display
# ------------------------------------------------------------

filename = dataDirectory + "Plot_9_Unblocked_GFLOPS_vs_N_Grid_Comparison"

plt.savefig(filename + ".pdf", bbox_inches="tight")
plt.savefig(filename + ".png", dpi=300, bbox_inches="tight")

plt.show()


# ============================================================
# Plot 2: Unblocked LU - Strong Scaling Efficiency
# ============================================================

# ------------------------------------------------------------
# Plot settings
# ------------------------------------------------------------

N_unique = np.sort(np.unique(n_unblocked))

colors = plt.cm.viridis(np.linspace(0, 1, len(N_unique)))

fig, ax = plt.subplots(figsize=(10, 6))

# ------------------------------------------------------------
# Loop over matrix sizes
# ------------------------------------------------------------

for i, N in enumerate(N_unique):

    mask_N = (n_unblocked == N)

    P_unique = np.sort(np.unique(nprocs_unblocked[mask_N]))

    x_values = []
    efficiency_values = []

    # Average single-processor reference time
    mask_serial = mask_N & (nprocs_unblocked == 1)

    if not np.any(mask_serial):
        print(f"Skipping N={N}: no serial measurements")
        continue

    T1 = np.mean(time_unblocked[mask_serial])

    # Calculate parallel efficiency
    for p in P_unique:

        mask = mask_N & (nprocs_unblocked == p)

        Tp = np.mean(time_unblocked[mask])

        efficiency = T1 / (p * Tp)

        x_values.append(N / p)
        efficiency_values.append(efficiency)

    # Sort by x-axis
    order = np.argsort(x_values)

    x_values = np.array(x_values)[order]
    efficiency_values = np.array(efficiency_values)[order]

    # Plot curve for this matrix size
    ax.plot(
        x_values,
        efficiency_values,
        marker="o",
        linestyle="-",
        linewidth=2,
        markersize=6,
        color=colors[i],
        label=f"N={N}"
    )

# ------------------------------------------------------------
# Formatting
# ------------------------------------------------------------

ax.axhline(
    1.0,
    color="black",
    linestyle="--",
    linewidth=1,
    label="Ideal Efficiency"
)

ax.set_xlabel(r"$N/N_{\mathrm{procs}}$")
ax.set_ylabel("Parallel Efficiency")

ax.set_title("Unblocked LU: Strong Scaling Efficiency")

ax.grid(True, alpha=0.3)
ax.legend()

from matplotlib.ticker import ScalarFormatter

# Log-log axes
ax.set_xscale("log")

# Display normal numbers instead of scientific notation
ax.xaxis.set_major_formatter(ScalarFormatter())
ax.yaxis.set_major_formatter(ScalarFormatter())

# Disable scientific notation
ax.ticklabel_format(style="plain", axis="both")

plt.tight_layout()

# ------------------------------------------------------------
# Save and display
# ------------------------------------------------------------

plt.savefig(
    dataDirectory + "Plot_2_Unblocked_Strong_Scaling_Efficiency.png",
    bbox_inches="tight"
)

plt.show()

# ============================================================
# Plot 3: Unblocked LU - Strong Scaling GFLOPS
# ============================================================

# ------------------------------------------------------------
# Plot settings
# ------------------------------------------------------------

N_unique = np.sort(np.unique(n_unblocked))

colors = plt.cm.viridis(np.linspace(0, 1, len(N_unique)))

fig, ax = plt.subplots(figsize=(10, 6))

# ------------------------------------------------------------
# Loop over matrix sizes
# ------------------------------------------------------------

for i, N in enumerate(N_unique):

    mask_N = (n_unblocked == N)

    P_unique = np.sort(np.unique(nprocs_unblocked[mask_N]))

    x_values = []
    gflops_values = []

    # Calculate average GFLOPS
    for p in P_unique:

        mask = mask_N & (nprocs_unblocked == p)

        avg_gflops = np.mean(gflops_unblocked[mask])

        x_values.append(N / p)
        gflops_values.append(avg_gflops)

    # Sort by x-axis
    order = np.argsort(x_values)

    x_values = np.array(x_values)[order]
    gflops_values = np.array(gflops_values)[order]

    # Plot curve for this matrix size
    ax.plot(
        x_values,
        gflops_values,
        marker="o",
        linestyle="-",
        linewidth=2,
        markersize=6,
        color=colors[i],
        label=f"N={N}"
    )

# ------------------------------------------------------------
# Formatting
# ------------------------------------------------------------

ax.set_xlabel(r"$N/N_{\mathrm{procs}}$")
ax.set_ylabel("Performance [GFLOPS]")

ax.set_title("Unblocked LU: Strong Scaling Performance")

ax.grid(True, alpha=0.3)
ax.legend()
from matplotlib.ticker import ScalarFormatter

# Log-log axes
ax.set_xscale("log")
ax.set_yscale("log")

# Display normal numbers instead of scientific notation
ax.xaxis.set_major_formatter(ScalarFormatter())
ax.yaxis.set_major_formatter(ScalarFormatter())

# Disable scientific notation
ax.ticklabel_format(style="plain", axis="both")
plt.tight_layout()

# ------------------------------------------------------------
# Save and display
# ------------------------------------------------------------

plt.savefig(
    dataDirectory + "Plot_3_Unblocked_Strong_Scaling_GFLOPS.png",
    bbox_inches="tight"
)

plt.show()


# ============================================================
# Plot 4: Unblocked LU - Parallel Efficiency vs MPI Ranks
# ============================================================

# ------------------------------------------------------------
# Plot settings
# ------------------------------------------------------------

N_unique = np.sort(np.unique(n_unblocked))

colors = plt.cm.viridis(np.linspace(0, 1, len(N_unique)))

fig, ax = plt.subplots(figsize=(10, 6))

# ------------------------------------------------------------
# Loop over matrix sizes
# ------------------------------------------------------------

for i, N in enumerate(N_unique):

    mask_N = (n_unblocked == N)

    P_unique = np.sort(np.unique(nprocs_unblocked[mask_N]))

    x_values = []
    efficiency_values = []

    # Average single-processor reference time
    mask_serial = mask_N & (nprocs_unblocked == 1)

    if not np.any(mask_serial):
        print(f"Skipping N={N}: no serial measurements")
        continue

    T1 = np.mean(time_unblocked[mask_serial])

    # Calculate parallel efficiency
    for p in P_unique:

        mask = mask_N & (nprocs_unblocked == p)

        # Average all repetitions
        Tp = np.mean(time_unblocked[mask])

        efficiency = T1 / (p * Tp)

        x_values.append(p)
        efficiency_values.append(efficiency)

    # Plot curve for this matrix size
    ax.plot(
        x_values,
        efficiency_values,
        marker="o",
        linestyle="-",
        linewidth=2,
        markersize=6,
        color=colors[i],
        label=f"N={N}"
    )

# ------------------------------------------------------------
# Formatting
# ------------------------------------------------------------

ax.axhline(
    1.0,
    color="black",
    linestyle="--",
    linewidth=1,
    label="Ideal Efficiency"
)

ax.set_xlabel("Number of MPI Ranks")
ax.set_ylabel("Parallel Efficiency")

ax.set_title("Unblocked LU: Parallel Efficiency vs MPI Ranks")

# Logarithmic x-axis with normal integer labels
ax.set_xscale("log", base=2)

P_all = np.sort(np.unique(nprocs_unblocked))

ax.set_xticks(P_all)
ax.set_xticklabels(P_all)

ax.grid(True, alpha=0.3)
ax.legend()

plt.tight_layout()

# ------------------------------------------------------------
# Save and display
# ------------------------------------------------------------

plt.savefig(
    dataDirectory + "Plot_4_Unblocked_Efficiency_vs_MPI_Ranks.png",
    bbox_inches="tight"
)
plt.show()


# ============================================================
# Plot 5: Unblocked LU - Parallel Efficiency vs n/nprocs
# Constant n^2/nprocs Curves
# ============================================================

# ------------------------------------------------------------
# Plot settings
# ------------------------------------------------------------

workload_targets = [255**2, 511**2, 1023**2]
tolerance = 0.30

colors = plt.cm.viridis(
    np.linspace(0, 1, len(workload_targets))
)

fig, ax = plt.subplots(figsize=(10, 6))

# ------------------------------------------------------------
# Loop over constant-workload curves
# ------------------------------------------------------------

for i, target in enumerate(workload_targets):

    P_unique = np.sort(np.unique(nprocs_unblocked))

    x_values = []
    time_values = []
    rank_values = []
    selected_N = []

    for p in P_unique:

        mask_p = (nprocs_unblocked == p)
        N_available = np.unique(n_unblocked[mask_p])

        if len(N_available) == 0:
            continue

        # Find matrix size closest to target workload
        workloads = N_available**2 / p
        idx = np.argmin(np.abs(workloads - target))

        N_best = N_available[idx]
        relative_error = abs(workloads[idx] - target) / target

        if relative_error > tolerance:
            continue

        # Average repetitions
        mask = (
            (n_unblocked == N_best) &
            (nprocs_unblocked == p)
        )

        Tp = np.mean(time_unblocked[mask])

        x_values.append(N_best / p)
        time_values.append(Tp)
        rank_values.append(p)
        selected_N.append(N_best)

    if len(rank_values) == 0:
        continue

    # Original parallel efficiency definition:
    # E = T1 / (p * Tp)
    # Reference is the first selected processor count.
    # For the original definition, require p=1.
    if rank_values[0] != 1:
        print(f"Skipping target {target}: no 1-rank reference")
        continue

    T1 = time_values[0]

    efficiency_values = [
        T1 / (p * Tp)
        for p, Tp in zip(rank_values, time_values)
    ]

    # Sort by horizontal axis
    order = np.argsort(x_values)

    x_values = np.array(x_values)[order]
    efficiency_values = np.array(efficiency_values)[order]

    ax.plot(
        x_values,
        efficiency_values,
        marker="o",
        linestyle="-",
        linewidth=2,
        markersize=6,
        color=colors[i],
        label=rf"$n^2/(PQ) \approx {target:,.0f}$"
    )

# ------------------------------------------------------------
# Formatting
# ------------------------------------------------------------

ax.axhline(
    1.0,
    color="black",
    linestyle="--",
    linewidth=1,
    label="Ideal Efficiency"
)

ax.set_xlabel(r"$n/N_{\mathrm{procs}}$")
ax.set_ylabel("Parallel Efficiency")
ax.set_title("Unblocked LU: Constant Workload Efficiency")

ax.grid(True, alpha=0.3)
ax.legend()

plt.tight_layout()

# ------------------------------------------------------------
# Save and display
# ------------------------------------------------------------

plt.savefig(
    dataDirectory + "Plot_5_Unblocked_Constant_Workload_Efficiency.png",
    bbox_inches="tight"
)

plt.show()



# ============================================================
# Plot 6: Unblocked LU - GFLOPS vs n/nprocs
# Constant n^2/nprocs Curves
# ============================================================

# ------------------------------------------------------------
# Plot settings
# ------------------------------------------------------------

workload_targets = [255**2, 511**2, 1023**2]
tolerance = 0.30

colors = plt.cm.viridis(
    np.linspace(0, 1, len(workload_targets))
)

fig, ax = plt.subplots(figsize=(10, 6))

# ------------------------------------------------------------
# Loop over constant-workload curves
# ------------------------------------------------------------

for i, target in enumerate(workload_targets):

    P_unique = np.sort(np.unique(nprocs_unblocked))

    x_values = []
    gflops_values = []

    for p in P_unique:

        mask_p = (nprocs_unblocked == p)
        N_available = np.unique(n_unblocked[mask_p])

        if len(N_available) == 0:
            continue

        # Find matrix size closest to target workload
        workloads = N_available**2 / p
        idx = np.argmin(np.abs(workloads - target))

        N_best = N_available[idx]
        relative_error = abs(workloads[idx] - target) / target

        if relative_error > tolerance:
            continue

        # Average all repetitions
        mask = (
            (n_unblocked == N_best) &
            (nprocs_unblocked == p)
        )

        avg_gflops = np.mean(gflops_unblocked[mask])

        x_values.append(N_best / p)
        gflops_values.append(avg_gflops)

    if len(x_values) == 0:
        continue

    # Sort by horizontal axis
    order = np.argsort(x_values)

    x_values = np.array(x_values)[order]
    gflops_values = np.array(gflops_values)[order]

    ax.plot(
        x_values,
        gflops_values,
        marker="o",
        linestyle="-",
        linewidth=2,
        markersize=6,
        color=colors[i],
        label=rf"$n^2/(PQ) \approx {target:,.0f}$"
    )

# ------------------------------------------------------------
# Formatting
# ------------------------------------------------------------

ax.set_xlabel(r"$n/N_{\mathrm{procs}}$")
ax.set_ylabel("Performance [GFLOPS]")
ax.set_title("Unblocked LU: Constant Workload Performance")

ax.grid(True, alpha=0.3)
ax.legend()

plt.tight_layout()

# ------------------------------------------------------------
# Save and display
# ------------------------------------------------------------

plt.savefig(
    dataDirectory + "Plot_6_Unblocked_Constant_Workload_GFLOPS.png",
    bbox_inches="tight"
)

plt.show()

