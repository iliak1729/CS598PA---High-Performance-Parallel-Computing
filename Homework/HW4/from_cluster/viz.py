import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.ticker import ScalarFormatter

# ============================================================
# Load Parallel Tridiagonal Solver Data
# ============================================================

dataDirectory = "./Homework/HW4/from_cluster/"

datafile = dataDirectory + "convergence.csv"

data = pd.read_csv(datafile)

N_values = data["N"].to_numpy(dtype=int)
nprocs = data["nproc"].to_numpy(dtype=int)
dx_values = data["dx"].to_numpy(dtype=float)
L2_errors = data["L2_error"].to_numpy(dtype=float)
solver_times = data["avg_solver_time"].to_numpy(dtype=float)


# ============================================================
# Plot 1: Parallel Tridiagonal - L2 Error vs N
# ============================================================

# ------------------------------------------------------------
# Plot settings
# ------------------------------------------------------------

P_unique = np.sort(np.unique(nprocs))

colors = plt.cm.viridis(np.linspace(0, 1, len(P_unique)))

fig, ax = plt.subplots(figsize=(10, 6))

# ------------------------------------------------------------
# Loop over MPI process counts
# ------------------------------------------------------------

for i, p in enumerate(P_unique):

    mask_p = (nprocs == p)

    N_unique = np.sort(np.unique(N_values[mask_p]))

    x_values = []
    error_values = []

    # Collect L2 errors for each problem size
    for N in N_unique:

        mask = (N_values == N) & (nprocs == p)

        avg_error = np.mean(L2_errors[mask])

        x_values.append(N)
        error_values.append(avg_error)

    if len(x_values) == 0:
        continue

    # Plot curve for this MPI process count
    ax.plot(
        x_values,
        error_values,
        marker="o",
        linestyle="-",
        linewidth=2,
        markersize=6,
        color=colors[i],
        label=f"{p} MPI Ranks"
    )

# ------------------------------------------------------------
# Second-order convergence reference
# ------------------------------------------------------------

mask_serial = (nprocs == 1)

N_serial = N_values[mask_serial]
error_serial = L2_errors[mask_serial]

order = np.argsort(N_serial)
N_serial = N_serial[order]
error_serial = error_serial[order]

# Anchor reference line at the smallest serial problem
N_ref = N_serial[0]
E_ref = error_serial[0]

second_order = E_ref * ((N_ref + 1) / (N_serial + 1))**2

ax.plot(
    N_serial,
    second_order,
    color="black",
    linestyle="--",
    linewidth=2,
    label="Second-Order Convergence"
)

# ------------------------------------------------------------
# Formatting
# ------------------------------------------------------------

ax.set_xlabel("Number of Interior Unknowns N")
ax.set_ylabel("L2 Error")

ax.set_title("Parallel Tridiagonal: L2 Error vs N")

ax.set_xscale("log", base=2)
ax.set_yscale("log")

N_all = np.sort(np.unique(N_values))
ax.set_xticks(N_all)
ax.set_xticklabels(N_all, rotation=45)

ax.grid(True, alpha=0.3)
ax.legend(title="MPI Ranks")

plt.tight_layout()

# ------------------------------------------------------------
# Save and display
# ------------------------------------------------------------

filename = dataDirectory + "Plot_1_Tridiagonal_L2_Error_vs_N"

plt.savefig(filename + ".pdf", bbox_inches="tight")
plt.savefig(filename + ".png", dpi=300, bbox_inches="tight")

plt.show()


# ============================================================
# Plot 2: Parallel Tridiagonal - Strong Scaling Efficiency
# Efficiency vs N/Nprocs
# ============================================================

# ------------------------------------------------------------
# Plot settings
# ------------------------------------------------------------

N_unique = np.sort(np.unique(N_values))

colors = plt.cm.viridis(np.linspace(0, 1, len(N_unique)))

fig, ax = plt.subplots(figsize=(10, 6))

# ------------------------------------------------------------
# Loop over problem sizes
# ------------------------------------------------------------

for i, N in enumerate(N_unique):

    mask_N = (N_values == N)

    P_unique = np.sort(np.unique(nprocs[mask_N]))

    x_values = []
    efficiency_values = []

    # Single-process reference time
    mask_serial = mask_N & (nprocs == 1)

    if not np.any(mask_serial):
        print(f"Skipping N={N}: no serial measurements")
        continue

    T1 = np.mean(solver_times[mask_serial])

    # Calculate parallel efficiency
    for p in P_unique:

        mask = mask_N & (nprocs == p)

        Tp = np.mean(solver_times[mask])

        efficiency = T1 / (p * Tp)

        x_values.append(N / p)
        efficiency_values.append(efficiency)

    # Sort by horizontal axis
    order = np.argsort(x_values)

    x_values = np.array(x_values)[order]
    efficiency_values = np.array(efficiency_values)[order]

    # Plot curve for this problem size
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
# Ideal parallel efficiency
# ------------------------------------------------------------

ax.axhline(
    1.0,
    color="black",
    linestyle="--",
    linewidth=2,
    label="Ideal Efficiency"
)

# ------------------------------------------------------------
# Formatting
# ------------------------------------------------------------

ax.set_xlabel(r"$N/N_{\mathrm{procs}}$")
ax.set_ylabel("Parallel Efficiency")

ax.set_title("Parallel Tridiagonal: Strong Scaling Efficiency")

# Log-log axes
ax.set_xscale("log", base=2)


# Display normal numbers instead of scientific notation
ax.xaxis.set_major_formatter(ScalarFormatter())
ax.yaxis.set_major_formatter(ScalarFormatter())

ax.grid(True, which="both", alpha=0.3)

# Display normal numbers instead of scientific notation
ax.xaxis.set_major_formatter(ScalarFormatter())

ax.grid(True, alpha=0.3)

ax.legend(
    title="Problem Size",
    bbox_to_anchor=(1.02, 1),
    loc="upper left"
)

plt.tight_layout()

# ------------------------------------------------------------
# Save and display
# ------------------------------------------------------------

filename = dataDirectory + "Plot_2_Tridiagonal_Strong_Scaling_Efficiency"

plt.savefig(filename + ".pdf", bbox_inches="tight")
plt.savefig(filename + ".png", dpi=300, bbox_inches="tight")

plt.show()




# ============================================================
# Plot 4: Parallel Tridiagonal - Temperature Distribution
# Numerical vs Exact Solution for Multiple Resolutions
# ============================================================

# ------------------------------------------------------------
# Plot settings
# ------------------------------------------------------------

N_plot = [31, 63, 127, 255]

colors = plt.cm.viridis(np.linspace(0, 1, len(N_plot)))

fig, ax = plt.subplots(figsize=(10, 6))

# ------------------------------------------------------------
# Loop over resolutions
# ------------------------------------------------------------

for i, N in enumerate(N_plot):

    # Load temperature data
    temperature_file = dataDirectory + f"TemperatureFile{N}.txt"

    temperature_data = np.loadtxt(
        temperature_file,
        skiprows=1
    )

    x = temperature_data[:, 0]
    T = temperature_data[:, 1]
    T_exact = temperature_data[:, 4]

    # Sort by x coordinate
    order = np.argsort(x)

    x = x[order]
    T = T[order]
    T_exact = T_exact[order]

    # --------------------------------------------------------
    # Numerical solution
    # --------------------------------------------------------

    ax.plot(
        x,
        T,
        marker="o",
        linestyle="-",
        linewidth=2,
        markersize=5,
        markevery=max(1, len(x) // 15),
        color=colors[i],
        label=f"Numerical, N={N}"
    )

    # --------------------------------------------------------
    # Exact solution
    # --------------------------------------------------------

    ax.plot(
        x,
        T_exact,
        linestyle="--",
        linewidth=2,
        color=colors[i],
        label=f"Exact, N={N}"
    )

# ------------------------------------------------------------
# Formatting
# ------------------------------------------------------------

ax.set_xlabel("Position x")
ax.set_ylabel("Temperature T")

ax.set_title("Parallel Tridiagonal: Temperature Distribution")

ax.grid(True, alpha=0.3)

ax.legend(
    loc="best",
    fontsize=9,
    ncol=2
)

plt.tight_layout()

# ------------------------------------------------------------
# Save and display
# ------------------------------------------------------------

filename = dataDirectory + "Plot_4_Tridiagonal_Temperature_Distribution"

plt.savefig(filename + ".pdf", bbox_inches="tight")
plt.savefig(filename + ".png", dpi=300, bbox_inches="tight")

plt.show()


# ============================================================
# Plot 5: Parallel Tridiagonal - Solver Time vs N/Nprocs
# ============================================================

# ------------------------------------------------------------
# Plot settings
# ------------------------------------------------------------

N_unique = np.sort(np.unique(N_values))

colors = plt.cm.viridis(np.linspace(0, 1, len(N_unique)))

fig, ax = plt.subplots(figsize=(10, 6))

# ------------------------------------------------------------
# Loop over problem sizes
# ------------------------------------------------------------

for i, N in enumerate(N_unique):

    mask_N = (N_values == N)

    P_unique = np.sort(np.unique(nprocs[mask_N]))

    x_values = []
    time_values = []

    for p in P_unique:

        mask = mask_N & (nprocs == p)

        # Average solver time
        Tp = np.mean(solver_times[mask])

        # Local problem size
        local_N = N / p

        x_values.append(local_N)
        time_values.append(Tp)

    # Sort by horizontal axis
    order = np.argsort(x_values)

    x_values = np.array(x_values)[order]
    time_values = np.array(time_values)[order]

    # Plot curve for this problem size
    ax.plot(
        x_values,
        time_values,
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
ax.set_ylabel("Average Solver Time (s)")

ax.set_title("Parallel Tridiagonal: Solver Time vs Local Problem Size")

# Log-log axes
ax.set_xscale("log", base=2)
ax.set_yscale("log", base=10)

ax.grid(True, which="both", alpha=0.3)

ax.legend(
    title="Problem Size",
    bbox_to_anchor=(1.02, 1),
    loc="upper left"
)

plt.tight_layout()

# ------------------------------------------------------------
# Save and display
# ------------------------------------------------------------

filename = dataDirectory + "Plot_5_Tridiagonal_Solver_Time"

plt.savefig(filename + ".pdf", bbox_inches="tight")
plt.savefig(filename + ".png", dpi=300, bbox_inches="tight")

plt.show()

# ============================================================
# Plot 6: Parallel Tridiagonal - Solver Time vs N
# ============================================================

# ------------------------------------------------------------
# Plot settings
# ------------------------------------------------------------

P_unique = np.sort(np.unique(nprocs))

colors = plt.cm.viridis(np.linspace(0, 1, len(P_unique)))

fig, ax = plt.subplots(figsize=(10, 6))

# ------------------------------------------------------------
# Loop over MPI process counts
# ------------------------------------------------------------

for i, p in enumerate(P_unique):

    mask_p = (nprocs == p)

    N_available = np.sort(np.unique(N_values[mask_p]))

    x_values = []
    time_values = []

    for N in N_available:

        mask = (
            (N_values == N) &
            (nprocs == p)
        )

        # Average solver time
        Tp = np.mean(solver_times[mask])

        x_values.append(N)
        time_values.append(Tp)

    # Plot curve for this MPI process count
    ax.plot(
        x_values,
        time_values,
        marker="o",
        linestyle="-",
        linewidth=2,
        markersize=6,
        color=colors[i],
        label=f"P={p}"
    )

# ------------------------------------------------------------
# Formatting
# ------------------------------------------------------------

ax.set_xlabel("Problem Size N")
ax.set_ylabel("Average Solver Time (s)")

ax.set_title("Parallel Tridiagonal: Solver Time vs N")

# Log-log axes
ax.set_xscale("log", base=2)
ax.set_yscale("log", base=10)

ax.grid(True, which="both", alpha=0.3)

ax.legend(
    title="MPI Ranks",
    bbox_to_anchor=(1.02, 1),
    loc="upper left"
)

plt.tight_layout()

# ------------------------------------------------------------
# Save and display
# ------------------------------------------------------------

filename = dataDirectory + "Plot_6_Tridiagonal_Solver_Time_vs_N"

plt.savefig(filename + ".pdf", bbox_inches="tight")
plt.savefig(filename + ".png", dpi=300, bbox_inches="tight")

plt.show()
