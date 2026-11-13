import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# ============================================================
# Load CSV Data
# ============================================================

filename = "./Project_1/results/FromCluster/convergence.csv"  # Change to your actual filename

data = pd.read_csv(filename)

# ============================================================
# Grid Information
# ============================================================

N  = data["N"].to_numpy(dtype=int)
Nx = data["Nx"].to_numpy(dtype=int)
Ny = data["Ny"].to_numpy(dtype=int)
Nz = data["Nz"].to_numpy(dtype=int)

h = data["h"].to_numpy(dtype=float)

# ============================================================
# MPI Decomposition
# ============================================================

ranks = data["ranks"].to_numpy(dtype=int)

Px = data["Px"].to_numpy(dtype=int)
Py = data["Py"].to_numpy(dtype=int)
Pz = data["Pz"].to_numpy(dtype=int)

# ============================================================
# Solver Results
# ============================================================

iterations = data["iterations"].to_numpy(dtype=int)

relative_residual = data["relative_residual"].to_numpy(dtype=float)
rms_error = data["rms_error"].to_numpy(dtype=float)

solve_time = data["solve_time_s"].to_numpy(dtype=float)

status = data["status"].to_numpy(dtype=str)

# ============================================================
# Verify Data
# ============================================================

print(f"Loaded {len(N)} simulations")

print("Grid resolutions:", np.unique(N))
print("MPI ranks:", np.unique(ranks))
print("Statuses:", np.unique(status))
# ============================================================
# Grid Convergence - Multiple MPI Rank Counts
# ============================================================

fig, ax = plt.subplots(figsize=(10, 7))

rank_counts = np.unique(ranks[status == "ok"])

colors = plt.get_cmap("tab10")

for idx, P in enumerate(rank_counts):

    mask = (ranks == P) & (status == "ok")

    # Multiple decompositions may exist for the same N and P
    # Average their RMS errors
    subset = pd.DataFrame({
        "N": N[mask],
        "h": h[mask],
        "error": rms_error[mask]
    })

    convergence = (
        subset.groupby("N", as_index=False)
        .agg({"h": "mean", "error": "mean"})
        .sort_values("h", ascending=False)
    )

    if convergence.empty:
        continue
    linewidth_value=7.5 - 0.5 * idx

    ax.loglog(
        convergence["h"],
        convergence["error"],
        marker="o",
        linestyle="-",
        linewidth=linewidth_value,
        markersize=6,
        color=colors(idx % 10),
        label=f"{P} MPI ranks"
    )

# ============================================================
# Second-Order Reference
# ============================================================

valid = (status == "ok") & (rms_error > 0)

h_ref = np.sort(np.unique(h[valid]))

# Anchor reference at the largest grid spacing
h0 = h_ref[-1]
e0 = np.mean(rms_error[valid & np.isclose(h, h0)])

reference = e0 * (h_ref / h0)**2

ax.loglog(
    h_ref,
    reference,
    "k--",
    linewidth=2.5,
    label=r"$O(h^2)$"
)

# ============================================================
# Formatting
# ============================================================

ax.set_xlabel(r"Grid spacing, $h$", fontsize=14)
ax.set_ylabel(r"RMS Error", fontsize=14)
ax.set_title("3D Poisson Solver - Grid Convergence", fontsize=16)

ax.grid(True, which="major", linestyle="-", alpha=0.5)
ax.grid(True, which="minor", linestyle=":", alpha=0.25)

ax.legend(
    loc="center left",
    bbox_to_anchor=(1.02, 0.5),
    fontsize=11,
    title="Processor Count"
)

ax.tick_params(axis="both", which="major", labelsize=12)

plt.tight_layout()
plt.show()

# ============================================================
# Local Problem Size vs Time per Iteration
# With One Ideal Strong Scaling Reference
# ============================================================

valid = (
    (status == "ok") &
    (iterations > 0) &
    (solve_time > 0)
)

# Local problem size
Mx = (Nx / Px) * (Ny / Py) * (Nz / Pz)
# Mx = Nx * Ny * Nz
# Time per PCG iteration
time_per_iteration = np.full(len(N), np.nan)
time_per_iteration[valid] = solve_time[valid] / iterations[valid]

fig, ax = plt.subplots(figsize=(10, 7))

rank_counts = np.unique(ranks[valid])
colors = plt.get_cmap("tab10")

# ============================================================
# Measured Results
# ============================================================

for idx, P in enumerate(rank_counts):

    mask = valid & (ranks == P)

    subset = pd.DataFrame({
        "Mx": Mx[mask],
        "time_per_iteration": time_per_iteration[mask]
    })

    subset = (
        subset.groupby("Mx", as_index=False)
        .mean()
        .sort_values("Mx")
    )

    ax.loglog(
        subset["Mx"],
        subset["time_per_iteration"],
        marker="o",
        linestyle="-",
        linewidth=1.5 + 0.3 * idx,
        markersize=6,
        color=colors(idx % 10),
        label=f"{P} MPI ranks"
    )
# ============================================================
# Single Ideal Strong Scaling Reference (100 Points)
# ============================================================

# Choose one global resolution for the reference
reference_N = np.max(N[valid])

ref_mask = valid & (N == reference_N)

reference_data = pd.DataFrame({
    "ranks": ranks[ref_mask],
    "Mx": Mx[ref_mask],
    "time": time_per_iteration[ref_mask]
})

reference_data = (
    reference_data
    .groupby("ranks", as_index=False)
    .mean()
    .sort_values("ranks")
)

if len(reference_data) >= 2:

    P_ref = reference_data["ranks"].to_numpy()
    M_ref = reference_data["Mx"].to_numpy()
    T_ref = reference_data["time"].to_numpy()

    # Anchor at smallest MPI rank count
    M0 = M_ref[0]
    T0 = T_ref[0]

    # Generate 100 logarithmically spaced points
    M_ideal = np.logspace(
        np.log10(np.min(Mx[valid])),
        np.log10(np.max(Mx[valid])),
        100
    )

    # Ideal strong scaling: T ~ M_local
    T_ideal = T0 * (M_ideal / M0) / 9

    ax.loglog(
        M_ideal,
        T_ideal,
        "k--",
        linewidth=2.5,
        label=r"Ideal Strong Scaling ($1/P$)"
    )

# ============================================================
# Formatting
# ============================================================

ax.set_xlabel(
    r"Local Problem Size, $N_xN_yN_z/P$",
    fontsize=14
)

ax.set_ylabel(
    "Time per PCG Iteration (s)",
    fontsize=14
)

ax.set_title(
    "3D Poisson Solver - Local Problem Size vs Iteration Time",
    fontsize=16
)

ax.grid(
    True,
    which="major",
    linestyle="-",
    alpha=0.5
)

ax.grid(
    True,
    which="minor",
    linestyle=":",
    alpha=0.25
)

ax.legend(
    loc="center left",
    bbox_to_anchor=(1.02, 0.5),
    fontsize=11,
    title="MPI Ranks"
)

ax.tick_params(
    axis="both",
    which="major",
    labelsize=12
)

plt.tight_layout()
plt.show()

# ============================================================
# Strong Scaling: Time per Iteration vs MPI Ranks
# ============================================================

valid = (
    (status == "ok") &
    (iterations > 0) &
    (solve_time > 0)
)

time_per_iteration = np.full(len(N), np.nan)
time_per_iteration[valid] = solve_time[valid] / iterations[valid]

# Group by global resolution and MPI rank count
scaling_data = pd.DataFrame({
    "N": N[valid],
    "ranks": ranks[valid],
    "time_per_iteration": time_per_iteration[valid]
})

# Average repeated runs / different process decompositions
scaling_data = (
    scaling_data
    .groupby(["N", "ranks"], as_index=False)
    .agg({"time_per_iteration": "mean"})
)

resolutions = np.sort(scaling_data["N"].unique())
colors = plt.get_cmap("tab10")

fig, ax = plt.subplots(figsize=(10, 7))

# ============================================================
# Measured Strong Scaling
# ============================================================

for idx, n in enumerate(resolutions):

    subset = (
        scaling_data[scaling_data["N"] == n]
        .sort_values("ranks")
    )

    P = subset["ranks"].to_numpy()
    T = subset["time_per_iteration"].to_numpy()

    if len(P) < 2:
        continue

    ax.loglog(
        P,
        T,
        marker="o",
        linestyle="-",
        linewidth=2.0,
        markersize=7,
        color=colors(idx % 10),
        label=rf"$N={n}$"
    )

# ============================================================
# Single Ideal Strong Scaling Reference: T ~ 1/P
# ============================================================

# Choose resolution with the most rank counts
reference_N = (
    scaling_data.groupby("N")["ranks"]
    .nunique()
    .idxmax()
)

reference_data = (
    scaling_data[scaling_data["N"] == reference_N]
    .sort_values("ranks")
)

P_ref = reference_data["ranks"].to_numpy()
T_ref = reference_data["time_per_iteration"].to_numpy()

P0 = P_ref[0]
T0 = T_ref[0]

# Adjustable vertical shift
vertical_shift = 1000.0

# Smooth reference line
P_ideal = np.logspace(
    np.log10(scaling_data["ranks"].min()),
    np.log10(scaling_data["ranks"].max()),
    100
)

T_ideal = vertical_shift * T0 * P0 / P_ideal

ax.loglog(
    P_ideal,
    T_ideal,
    "k--",
    linewidth=2.5,
    label=r"Ideal Strong Scaling ($1/P$)"
)

# ============================================================
# Formatting
# ============================================================

ax.set_xlabel("MPI Ranks, $P$", fontsize=14)
ax.set_ylabel("Time per PCG Iteration (s)", fontsize=14)

ax.set_title(
    "3D Poisson Solver - Strong Scaling",
    fontsize=16
)

ax.set_xscale("log", base=2)
ax.set_yscale("log")

ax.grid(True, which="major", linestyle="-", alpha=0.5)
ax.grid(True, which="minor", linestyle=":", alpha=0.25)

ax.legend(
    loc="center left",
    bbox_to_anchor=(1.02, 0.5),
    fontsize=11,
    title="Global Resolution"
)

plt.tight_layout()
plt.show()

# ============================================================
# Collapsed Strong Scaling: Normalized Time vs MPI Ranks
# ============================================================

valid = (
    (status == "ok") &
    (iterations > 0) &
    (solve_time > 0)
)

# Global problem size
global_size = Nx * Ny * Nz

# Time per iteration
time_per_iteration = np.full(len(N), np.nan)
time_per_iteration[valid] = solve_time[valid] / iterations[valid]

# Normalize by global number of unknowns
normalized_time = time_per_iteration / global_size

scaling_data = pd.DataFrame({
    "N": N[valid],
    "ranks": ranks[valid],
    "normalized_time": normalized_time[valid]
})

scaling_data = (
    scaling_data
    .groupby(["N", "ranks"], as_index=False)
    .agg({"normalized_time": "mean"})
)

resolutions = np.sort(scaling_data["N"].unique())
colors = plt.get_cmap("tab10")

fig, ax = plt.subplots(figsize=(10, 7))

# ============================================================
# Measured Normalized Results
# ============================================================

for idx, n in enumerate(resolutions):

    subset = (
        scaling_data[scaling_data["N"] == n]
        .sort_values("ranks")
    )

    P = subset["ranks"].to_numpy()
    T = subset["normalized_time"].to_numpy()

    if len(P) < 2:
        continue

    ax.loglog(
        P,
        T,
        marker="o",
        linestyle="-",
        linewidth=2.0,
        markersize=7,
        color=colors(idx % 10),
        label=rf"$N={n}$"
    )

# ============================================================
# Ideal Strong Scaling Reference
# ============================================================

P_ideal = np.logspace(
    np.log10(scaling_data["ranks"].min()),
    np.log10(scaling_data["ranks"].max()),
    100
)

# Adjustable vertical shift
vertical_shift = 1.0

# Anchor to the first available data point
T0 = scaling_data["normalized_time"].iloc[0]
P0 = scaling_data["ranks"].iloc[0]

T_ideal = vertical_shift * T0 * P0 / P_ideal

ax.loglog(
    P_ideal,
    T_ideal,
    "k--",
    linewidth=2.5,
    label=r"Ideal $1/P$"
)

# ============================================================
# Formatting
# ============================================================

ax.set_xlabel("MPI Ranks, $P$", fontsize=14)

ax.set_ylabel(
    r"Normalized Time, $T_{\mathrm{iter}}/(N_xN_yN_z)$ (s/unknown)",
    fontsize=14
)

ax.set_title(
    "3D Poisson Solver - Strong Scaling",
    fontsize=16
)

ax.set_xscale("log", base=2)
ax.set_yscale("log")

ax.grid(True, which="major", linestyle="-", alpha=0.5)
ax.grid(True, which="minor", linestyle=":", alpha=0.25)

ax.legend(
    loc="center left",
    bbox_to_anchor=(1.02, 0.5),
    fontsize=11,
    title="Global Resolution"
)

plt.tight_layout()
plt.show()


# ============================================================
# Collapsed Weak Scaling Plot
# ============================================================

valid = (
    (status == "ok") &
    (iterations > 0) &
    (solve_time > 0)
)

# ============================================================
# Local Problem Size and Time per Iteration
# ============================================================

global_size = Nx * Ny * Nz
local_size = global_size / ranks

time_per_iteration = np.full(len(N), np.nan)
time_per_iteration[valid] = solve_time[valid] / iterations[valid]

# Normalize time by local problem size
normalized_time = time_per_iteration / local_size

# ============================================================
# Organize Data
# ============================================================

scaling_data = pd.DataFrame({
    "ranks": ranks[valid],
    "local_size": local_size[valid],
    "normalized_time": normalized_time[valid]
})

# Group approximately equal local problem sizes
# Round log2(local_size) to group similar workloads
scaling_data["local_group"] = (
    np.round(np.log2(scaling_data["local_size"])).astype(int)
)

scaling_data = (
    scaling_data
    .groupby(["local_group", "ranks"], as_index=False)
    .agg({
        "local_size": "mean",
        "normalized_time": "mean"
    })
)

local_groups = np.sort(scaling_data["local_group"].unique())

# ============================================================
# Plot
# ============================================================

fig, ax = plt.subplots(figsize=(10, 7))

colors = plt.get_cmap("tab10")

for idx, group in enumerate(local_groups):

    subset = (
        scaling_data[scaling_data["local_group"] == group]
        .sort_values("ranks")
    )

    if len(subset) < 2:
        continue

    P = subset["ranks"].to_numpy()
    T = subset["normalized_time"].to_numpy()

    local_N = subset["local_size"].mean()

    ax.plot(
        P,
        T,
        marker="o",
        linestyle="-",
        linewidth=2.0,
        markersize=7,
        color=colors(idx % 10),
        label=rf"$N_{{local}}\approx {local_N:.0f}$"
    )

# ============================================================
# Formatting
# ============================================================

ax.set_xscale("log", base=2)
ax.set_yscale("log")

ax.set_xlabel("MPI Ranks, $P$", fontsize=14)

ax.set_ylabel(
    r"Normalized Time, $T_{\mathrm{iter}}/N_{\mathrm{local}}$",
    fontsize=14
)

ax.set_title(
    "3D Poisson Solver - Collapsed Weak Scaling",
    fontsize=16
)

ax.grid(True, which="major", linestyle="-", alpha=0.5)
ax.grid(True, which="minor", linestyle=":", alpha=0.25)

ax.legend(
    loc="center left",
    bbox_to_anchor=(1.02, 0.5),
    fontsize=10,
    title="Local Problem Size"
)

plt.tight_layout()
plt.show()
# ============================================================
# Parallel Efficiency vs Local Problem Size
# ============================================================

valid = (
    (status == "ok") &
    (iterations > 0) &
    (solve_time > 0)
)

local_size = (Nx * Ny * Nz) / ranks

time_per_iteration = np.full(len(N), np.nan)
time_per_iteration[valid] = solve_time[valid] / iterations[valid]

efficiency_data = pd.DataFrame({
    "N": N[valid],
    "ranks": ranks[valid],
    "local_size": local_size[valid],
    "time": time_per_iteration[valid]
})

# Average across repeated runs and decompositions
efficiency_data = (
    efficiency_data
    .groupby(["N", "ranks"], as_index=False)
    .agg({
        "local_size": "mean",
        "time": "mean"
    })
)

resolutions = np.sort(efficiency_data["N"].unique())
colors = plt.get_cmap("tab10")

fig, ax = plt.subplots(figsize=(10, 7))

# ============================================================
# Plot Each Resolution
# ============================================================

for idx, n in enumerate(resolutions):

    subset = (
        efficiency_data[efficiency_data["N"] == n]
        .sort_values("ranks")
    )

    if len(subset) < 2:
        continue

    P = subset["ranks"].to_numpy()
    T = subset["time"].to_numpy()
    L = subset["local_size"].to_numpy()

    # Baseline
    P0 = P[0]
    T0 = T[0]

    # Parallel efficiency
    efficiency = 100 * (P0 * T0) / (P * T)

    ax.semilogx(
        L,
        efficiency,
        marker="o",
        linestyle="-",
        linewidth=2.5,
        markersize=7,
        color=colors(idx % 10),
        label=rf"$N={n}$"
    )

# ============================================================
# Ideal Efficiency Reference
# ============================================================

ax.axhline(
    100,
    color="black",
    linestyle="--",
    linewidth=2,
    label="Ideal Efficiency"
)

# ============================================================
# Formatting
# ============================================================

ax.set_xlabel(
    r"Local Problem Size, $N_xN_yN_z/P$",
    fontsize=14
)

ax.set_ylabel("Parallel Efficiency (%)", fontsize=14)

ax.set_title(
    "3D Poisson Solver - Parallel Efficiency",
    fontsize=16
)

ax.grid(True, which="major", linestyle="-", alpha=0.5)
ax.grid(True, which="minor", linestyle=":", alpha=0.25)

ax.legend(
    loc="center left",
    bbox_to_anchor=(1.02, 0.5),
    fontsize=11,
    title="Global Resolution"
)

plt.tight_layout()
plt.show()

# ============================================================
# Solve Time vs MPI Ranks
# ============================================================

valid = (
    (status == "ok") &
    (solve_time > 0)
)

# Organize data
timing_data = pd.DataFrame({
    "N": N[valid],
    "ranks": ranks[valid],
    "solve_time": solve_time[valid]
})

# Average repeated runs / different MPI decompositions
timing_data = (
    timing_data
    .groupby(["N", "ranks"], as_index=False)
    .agg({"solve_time": "mean"})
)

# ============================================================
# Plot
# ============================================================

fig, ax = plt.subplots(figsize=(10, 7))

resolutions = np.sort(timing_data["N"].unique())
colors = plt.get_cmap("tab10")

for idx, n in enumerate(resolutions):

    subset = (
        timing_data[timing_data["N"] == n]
        .sort_values("ranks")
    )

    if len(subset) == 0:
        continue

    ax.plot(
        subset["ranks"],
        subset["solve_time"],
        marker="o",
        linestyle="-",
        linewidth=2.5,
        markersize=7,
        color=colors(idx % 10),
        label=rf"$N={n}$"
    )

# ============================================================
# Formatting
# ============================================================

ax.set_xscale("log", base=2)
ax.set_yscale("log")

ax.set_xlabel("MPI Ranks", fontsize=14)
ax.set_ylabel("Solve Time (s)", fontsize=14)

ax.set_title(
    "3D Poisson Solver - Solve Time vs MPI Ranks",
    fontsize=16
)

ax.grid(True, which="major", linestyle="-", alpha=0.5)
ax.grid(True, which="minor", linestyle=":", alpha=0.25)

ax.legend(
    loc="center left",
    bbox_to_anchor=(1.02, 0.5),
    fontsize=11,
    title="Global Resolution"
)

ax.tick_params(axis="both", which="major", labelsize=12)

plt.tight_layout()
plt.show()

# ============================================================
# MPI Decomposition Comparison
# ============================================================

# Adjustable parameters
selected_N = 64
selected_ranks = 16

# Filter successful simulations
mask = (
    (status == "ok") &
    (N == selected_N) &
    (ranks == selected_ranks) &
    (solve_time > 0)
)

# Build dataframe
decomp_data = pd.DataFrame({
    "Px": Px[mask],
    "Py": Py[mask],
    "Pz": Pz[mask],
    "solve_time": solve_time[mask]
})

# Average repeated measurements of identical decompositions
decomp_data = (
    decomp_data
    .groupby(["Px", "Py", "Pz"], as_index=False)
    .agg({"solve_time": "mean"})
)

# Create decomposition labels
decomp_data["label"] = (
    decomp_data["Px"].astype(str) + "×" +
    decomp_data["Py"].astype(str) + "×" +
    decomp_data["Pz"].astype(str)
)

# Sort by solve time
decomp_data = decomp_data.sort_values("solve_time")

# ============================================================
# Plot
# ============================================================

fig, ax = plt.subplots(figsize=(10, 6))

colors = plt.get_cmap("tab10")(
    np.linspace(0, 1, len(decomp_data))
)

bars = ax.bar(
    decomp_data["label"],
    decomp_data["solve_time"] * 1000,
    color=colors,
    edgecolor="black",
    linewidth=0.8,
    width=0.65
)

# Label bars with their timing
for bar in bars:
    height = bar.get_height()

    ax.annotate(
        f"{height:.3f} ms",
        (bar.get_x() + bar.get_width() / 2, height),
        ha="center",
        va="bottom",
        fontsize=11,
        xytext=(0, 5),
        textcoords="offset points"
    )

# ============================================================
# Formatting
# ============================================================

ax.set_xlabel("MPI Decomposition", fontsize=14)
ax.set_ylabel("Solve Time (ms)", fontsize=14)

ax.set_title(
    f"MPI Decomposition Comparison — N={selected_N}, P={selected_ranks}",
    fontsize=15
)

ax.grid(
    axis="y",
    linestyle="--",
    alpha=0.3
)

ax.set_axisbelow(True)
ax.set_ylim(0, decomp_data["solve_time"].max() * 1150)

plt.tight_layout()
plt.show()

# ============================================================
# PCG Iterations vs Grid Resolution
# ============================================================

valid = (
    (status == "ok") &
    (iterations > 0)
)

# Organize data
iteration_data = pd.DataFrame({
    "N": N[valid],
    "ranks": ranks[valid],
    "iterations": iterations[valid]
})

# Average across different decompositions for same N and P
iteration_data = (
    iteration_data
    .groupby(["N", "ranks"], as_index=False)
    .agg({"iterations": "mean"})
)

# ============================================================
# Plot
# ============================================================

fig, ax = plt.subplots(figsize=(10, 7))

processor_counts = np.sort(iteration_data["ranks"].unique())

colors = plt.get_cmap("tab10")
markers = ["o", "s", "^", "D", "v", "P", "X", "*"]

for idx, p in enumerate(processor_counts):

    subset = (
        iteration_data[iteration_data["ranks"] == p]
        .sort_values("N")
    )

    ax.plot(
        subset["N"],
        subset["iterations"],
        marker=markers[idx % len(markers)],
        linestyle="-",
        linewidth=1.5 + 0.3 * idx,
        markersize=6,
        color=colors(idx % 10),
        label=rf"$P={p}$"
    )

# ============================================================
# O(N) Reference Line
# ============================================================

N_ref = np.logspace(
    np.log10(iteration_data["N"].min()),
    np.log10(iteration_data["N"].max()),
    100
)

# Anchor reference to N=64, iterations=159
N0 = 64
I0 = 159

I_ref = I0 * (N_ref / N0)

ax.plot(
    N_ref,
    I_ref,
    color="black",
    linestyle="--",
    linewidth=2.5,
    label=r"$O(N)$"
)

# ============================================================
# Formatting
# ============================================================

ax.set_xscale("log", base=2)
ax.set_yscale("log")

ax.set_xlabel("Grid Resolution, $N$", fontsize=14)
ax.set_ylabel("PCG Iterations", fontsize=14)

ax.set_title(
    "3D Poisson Solver - PCG Iterations vs Grid Resolution",
    fontsize=16
)

ax.grid(True, which="major", linestyle="-", alpha=0.5)
ax.grid(True, which="minor", linestyle=":", alpha=0.25)

ax.legend(
    loc="center left",
    bbox_to_anchor=(1.02, 0.5),
    fontsize=11,
    title="MPI Ranks"
)

plt.tight_layout()
plt.show()