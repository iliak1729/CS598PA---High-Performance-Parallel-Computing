import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import ScalarFormatter

# ============================================================
# Load blocked LU data
# ============================================================
dataDirectory = "./Homework/HW3/lu_c_files/cluster_results/"
blocked_file = dataDirectory + "lu_results_block_11317540.csv"
blocked = pd.read_csv(blocked_file)

n_blocked = blocked["n"].to_numpy(dtype=int)
P_blocked = blocked["P"].to_numpy(dtype=int)
Q_blocked = blocked["Q"].to_numpy(dtype=int)
bs_blocked = blocked["bs"].to_numpy(dtype=int)
run_blocked = blocked["run"].to_numpy(dtype=int)
time_blocked = blocked["time"].to_numpy(dtype=float)
gflops_blocked = blocked["gflops"].to_numpy(dtype=float)
nprocs_blocked = P_blocked * Q_blocked

# Select the block size used by all plots
BS_target = 32
if not np.any(bs_blocked == BS_target):
    raise ValueError(f"No measurements found for BS={BS_target}")



# ============================================================
# Plot 10: Blocked LU - GFLOPS vs N
# Comparison of 2x4 and 4x2 Processor Grids
# ============================================================

# ------------------------------------------------------------
# Plot settings
# ------------------------------------------------------------

BS_target = 32

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
        (P_blocked == P_target) &
        (Q_blocked == Q_target) &
        (bs_blocked == BS_target)
    )

    N_unique = np.sort(np.unique(n_blocked[mask_grid]))

    x_values = []
    gflops_values = []

    # Calculate average GFLOPS for each matrix size
    for N in N_unique:

        mask = (
            (n_blocked == N) &
            (P_blocked == P_target) &
            (Q_blocked == Q_target) &
            (bs_blocked == BS_target)
        )

        avg_gflops = np.mean(gflops_blocked[mask])

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
    f"Blocked LU: GFLOPS vs N for Different Processor Grids (BS={BS_target})"
)

ax.set_xscale("log", base=2)

N_all = np.sort(np.unique(n_blocked[bs_blocked == BS_target]))
ax.set_xticks(N_all)
ax.set_xticklabels(N_all)

ax.grid(True, alpha=0.3)
ax.legend(title="Processor Grid")

plt.tight_layout()

# ------------------------------------------------------------
# Save and display
# ------------------------------------------------------------

filename = (
    dataDirectory
    + f"Plot_10_Blocked_GFLOPS_vs_N_Grid_Comparison_BS{BS_target}"
)

plt.savefig(filename + ".pdf", bbox_inches="tight")
plt.savefig(filename + ".png", dpi=300, bbox_inches="tight")

plt.show()

# ============================================================
# Plot 2: Blocked LU - Strong Scaling Efficiency
# ============================================================
# ------------------------------------------------------------
# Plot settings
# ------------------------------------------------------------
N_unique = np.sort(np.unique(n_blocked[bs_blocked == BS_target]))
colors = plt.cm.viridis(np.linspace(0, 1, len(N_unique)))
fig, ax = plt.subplots(figsize=(10, 6))
# ------------------------------------------------------------
# Loop over matrix sizes
# ------------------------------------------------------------
for i, N in enumerate(N_unique):
    mask_N = (n_blocked == N) & (bs_blocked == BS_target)
    P_unique = np.sort(np.unique(nprocs_blocked[mask_N]))
    x_values = []
    efficiency_values = []
    # Average single-processor reference time
    mask_serial = mask_N & (nprocs_blocked == 1)
    if not np.any(mask_serial):
        print(f"Skipping N={N}: no serial measurements")
        continue
    T1 = np.mean(time_blocked[mask_serial])
    # Calculate parallel efficiency
    for p in P_unique:
        mask = mask_N & (nprocs_blocked == p)
        Tp = np.mean(time_blocked[mask])
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
ax.set_title(f"Blocked LU: Strong Scaling Efficiency (BS={BS_target})")
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
    dataDirectory + f"Plot_2_Blocked_Strong_Scaling_Efficiency_BS{BS_target}.png",
    bbox_inches="tight"
)
plt.show()
# ============================================================
# Plot 3: Blocked LU - Strong Scaling GFLOPS
# ============================================================
# ------------------------------------------------------------
# Plot settings
# ------------------------------------------------------------
N_unique = np.sort(np.unique(n_blocked[bs_blocked == BS_target]))
colors = plt.cm.viridis(np.linspace(0, 1, len(N_unique)))
fig, ax = plt.subplots(figsize=(10, 6))
# ------------------------------------------------------------
# Loop over matrix sizes
# ------------------------------------------------------------
for i, N in enumerate(N_unique):
    mask_N = (n_blocked == N) & (bs_blocked == BS_target)
    P_unique = np.sort(np.unique(nprocs_blocked[mask_N]))
    x_values = []
    gflops_values = []
    # Calculate average GFLOPS
    for p in P_unique:
        mask = mask_N & (nprocs_blocked == p)
        avg_gflops = np.mean(gflops_blocked[mask])
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
ax.set_title(f"Blocked LU: Strong Scaling Performance (BS={BS_target})")
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
    dataDirectory + f"Plot_3_Blocked_Strong_Scaling_GFLOPS_BS{BS_target}.png",
    bbox_inches="tight"
)
plt.show()
# ============================================================
# Plot 4: Blocked LU - Parallel Efficiency vs MPI Ranks
# ============================================================
# ------------------------------------------------------------
# Plot settings
# ------------------------------------------------------------
N_unique = np.sort(np.unique(n_blocked[bs_blocked == BS_target]))
colors = plt.cm.viridis(np.linspace(0, 1, len(N_unique)))
fig, ax = plt.subplots(figsize=(10, 6))
# ------------------------------------------------------------
# Loop over matrix sizes
# ------------------------------------------------------------
for i, N in enumerate(N_unique):
    mask_N = (n_blocked == N) & (bs_blocked == BS_target)
    P_unique = np.sort(np.unique(nprocs_blocked[mask_N]))
    x_values = []
    efficiency_values = []
    # Average single-processor reference time
    mask_serial = mask_N & (nprocs_blocked == 1)
    if not np.any(mask_serial):
        print(f"Skipping N={N}: no serial measurements")
        continue
    T1 = np.mean(time_blocked[mask_serial])
    # Calculate parallel efficiency
    for p in P_unique:
        mask = mask_N & (nprocs_blocked == p)
        # Average all repetitions
        Tp = np.mean(time_blocked[mask])
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
ax.set_title(f"Blocked LU: Parallel Efficiency vs MPI Ranks (BS={BS_target})")
# Logarithmic x-axis with normal integer labels
ax.set_xscale("log", base=2)
P_all = np.sort(np.unique(nprocs_blocked[bs_blocked == BS_target]))
ax.set_xticks(P_all)
ax.set_xticklabels(P_all)
ax.grid(True, alpha=0.3)
ax.legend()
plt.tight_layout()
# ------------------------------------------------------------
# Save and display
# ------------------------------------------------------------
plt.savefig(
    dataDirectory + f"Plot_4_Blocked_Efficiency_vs_MPI_Ranks_BS{BS_target}.png",
    bbox_inches="tight"
)
plt.show()
# ============================================================
# Plot 5: Blocked LU - Parallel Efficiency vs n/nprocs
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
    P_unique = np.sort(np.unique(nprocs_blocked[bs_blocked == BS_target]))
    x_values = []
    time_values = []
    rank_values = []
    selected_N = []
    for p in P_unique:
        mask_p = (nprocs_blocked == p) & (bs_blocked == BS_target)
        N_available = np.unique(n_blocked[mask_p])
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
            (n_blocked == N_best) &
            (bs_blocked == BS_target) &
            (nprocs_blocked == p)
        )
        Tp = np.mean(time_blocked[mask])
        x_values.append(N_best / p)
        time_values.append(Tp)
        rank_values.append(p)
        selected_N.append(N_best)
    if len(rank_values) == 0:
        continue
    # Work-normalized parallel efficiency:
    # E = (T1 / Tp) * (Np**3 / (p * N1**3))
    # Reference is the first selected processor count.
    # For the original definition, require p=1.
    if rank_values[0] != 1:
        print(f"Skipping target {target}: no 1-rank reference")
        continue
    T1 = time_values[0]
    N1 = selected_N[0]
    efficiency_values = [
        (T1 / Tp) * (Np**3 / (p * N1**3))
        for p, Tp, Np in zip(rank_values, time_values, selected_N)
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
ax.set_ylabel("Work-Normalized Parallel Efficiency")
ax.set_title(f"Blocked LU: Constant Workload Work-Normalized Efficiency (BS={BS_target})")
ax.grid(True, alpha=0.3)
ax.legend()
plt.tight_layout()
# ------------------------------------------------------------
# Save and display
# ------------------------------------------------------------
plt.savefig(
    dataDirectory + f"Plot_5_Blocked_Constant_Workload_Efficiency_BS{BS_target}.png",
    bbox_inches="tight"
)
plt.show()
# ============================================================
# Plot 6: Blocked LU - GFLOPS vs n/nprocs
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
    P_unique = np.sort(np.unique(nprocs_blocked[bs_blocked == BS_target]))
    x_values = []
    gflops_values = []
    for p in P_unique:
        mask_p = (nprocs_blocked == p) & (bs_blocked == BS_target)
        N_available = np.unique(n_blocked[mask_p])
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
            (n_blocked == N_best) &
            (bs_blocked == BS_target) &
            (nprocs_blocked == p)
        )
        avg_gflops = np.mean(gflops_blocked[mask])
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
ax.set_title(f"Blocked LU: Constant Workload Performance (BS={BS_target})")
ax.grid(True, alpha=0.3)
ax.legend()
plt.tight_layout()
# ------------------------------------------------------------
# Save and display
# ------------------------------------------------------------
plt.savefig(
    dataDirectory + f"Plot_6_Blocked_Constant_Workload_GFLOPS_BS{BS_target}.png",
    bbox_inches="tight"
)
plt.show()



# ============================================================
# Plot 7: Blocked LU - GFLOPS vs n/nprocs
# Different Block Sizes
# ============================================================

# ------------------------------------------------------------
# Plot settings
# ------------------------------------------------------------

N_target = 1023

BS_unique = np.sort(np.unique(bs_blocked))

colors = plt.cm.viridis(np.linspace(0, 1, len(BS_unique)))

fig, ax = plt.subplots(figsize=(10, 6))

# ------------------------------------------------------------
# Loop over block sizes
# ------------------------------------------------------------

for i, BS in enumerate(BS_unique):

    mask_BS = (
        (n_blocked == N_target) &
        (bs_blocked == BS)
    )

    P_unique = np.sort(np.unique(nprocs_blocked[mask_BS]))

    x_values = []
    gflops_values = []

    # Calculate average GFLOPS
    for p in P_unique:

        mask = (
            (n_blocked == N_target) &
            (bs_blocked == BS) &
            (nprocs_blocked == p)
        )

        avg_gflops = np.mean(gflops_blocked[mask])

        x_values.append(N_target / p)
        gflops_values.append(avg_gflops)

    if len(x_values) == 0:
        continue

    # Sort by x-axis
    order = np.argsort(x_values)

    x_values = np.array(x_values)[order]
    gflops_values = np.array(gflops_values)[order]

    # Plot curve for this block size
    ax.plot(
        x_values,
        gflops_values,
        marker="o",
        linestyle="-",
        linewidth=2,
        markersize=6,
        color=colors[i],
        label=f"BS={BS}"
    )

# ------------------------------------------------------------
# Formatting
# ------------------------------------------------------------

ax.set_xlabel(r"$n/N_{\mathrm{procs}}$")
ax.set_ylabel("Performance [GFLOPS]")

ax.set_title(
    f"Blocked LU: GFLOPS vs n/nprocs, N={N_target}"
)

ax.set_xscale("log")
ax.set_yscale("log")

from matplotlib.ticker import ScalarFormatter

ax.xaxis.set_major_formatter(ScalarFormatter())
ax.yaxis.set_major_formatter(ScalarFormatter())
ax.ticklabel_format(style="plain", axis="both")

ax.grid(True, alpha=0.3)
ax.legend(title="Block Size")

plt.tight_layout()

# ------------------------------------------------------------
# Save and display
# ------------------------------------------------------------

plt.savefig(
    dataDirectory + f"Plot_7_Blocked_GFLOPS_vs_nprocs_N{N_target}.png",
    bbox_inches="tight"
)

plt.show()


# ============================================================
# Plot 8: Blocked LU - GFLOPS vs Block Size
# Different Matrix Sizes
# ============================================================

# ------------------------------------------------------------
# Plot settings
# ------------------------------------------------------------

P_target = 1  # Total number of MPI ranks (P * Q)

N_unique = np.sort(np.unique(n_blocked))

colors = plt.cm.viridis(np.linspace(0, 1, len(N_unique)))

fig, ax = plt.subplots(figsize=(10, 6))

# ------------------------------------------------------------
# Loop over matrix sizes
# ------------------------------------------------------------

for i, N in enumerate(N_unique):

    mask_N = (
        (n_blocked == N) &
        (nprocs_blocked == P_target)
    )

    BS_unique = np.sort(np.unique(bs_blocked[mask_N]))

    x_values = []
    gflops_values = []

    # Calculate average GFLOPS for each block size
    for BS in BS_unique:

        mask = (
            (n_blocked == N) &
            (nprocs_blocked == P_target) &
            (bs_blocked == BS)
        )

        avg_gflops = np.mean(gflops_blocked[mask])

        x_values.append(BS)
        gflops_values.append(avg_gflops)

    if len(x_values) == 0:
        continue

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

ax.set_xlabel("Block Size")
ax.set_ylabel("Performance [GFLOPS]")

ax.set_title(
    f"Blocked LU: GFLOPS vs Block Size, MPI Ranks={P_target}"
)

# Logarithmic x-axis with normal block-size labels
ax.set_xscale("log", base=2)

BS_all = np.sort(np.unique(bs_blocked))
ax.set_xticks(BS_all)
ax.set_xticklabels(BS_all)

ax.grid(True, alpha=0.3)
ax.legend(title="Matrix Size")

plt.tight_layout()

# ------------------------------------------------------------
# Save and display
# ------------------------------------------------------------

plt.savefig(
    dataDirectory + f"Plot_8_Blocked_GFLOPS_vs_Block_Size_P{P_target}.png",
    bbox_inches="tight"
)

plt.show()
