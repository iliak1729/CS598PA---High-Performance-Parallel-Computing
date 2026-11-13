import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# ============================================================
# Load CSV Data
# ============================================================

filename = "./Project_1/results/FromCluster/convergence_Corrected.csv"  # Change to your actual filename

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
# Grid Convergence Study
# ============================================================

# Only include successful simulations
mask = (status == "ok")

# Create a dataframe with valid results
convergence_data = pd.DataFrame({
    "N": N[mask],
    "h": h[mask],
    "rms_error": rms_error[mask]
})

# Average RMS error across MPI decompositions
# (These should be nearly identical)
convergence = (
    convergence_data
    .groupby("N", as_index=False)
    .agg({
        "h": "mean",
        "rms_error": "mean"
    })
    .sort_values("h", ascending=False)
)

h_conv = convergence["h"].to_numpy()
error_conv = convergence["rms_error"].to_numpy()
N_conv = convergence["N"].to_numpy()

# ============================================================
# Calculate Observed Convergence Order
# ============================================================

orders = np.log(error_conv[:-1] / error_conv[1:]) / \
         np.log(h_conv[:-1] / h_conv[1:])

# Overall convergence order
p = np.polyfit(np.log(h_conv), np.log(error_conv), 1)[0]

print("\nGrid Convergence Results")
print("------------------------------------------------")
print(f"{'N':>8} {'h':>14} {'RMS Error':>16} {'Order':>10}")

for i in range(len(N_conv)):
    order_str = f"{orders[i-1]:.4f}" if i > 0 else "---"

    print(
        f"{N_conv[i]:8d} "
        f"{h_conv[i]:14.6e} "
        f"{error_conv[i]:16.6e} "
        f"{order_str:>10}"
    )

print("------------------------------------------------")
print(f"Overall observed convergence order: {p:.4f}")

# ============================================================
# Second-Order Reference Line
# ============================================================

# Anchor reference line at coarsest resolution
reference = error_conv[0] * (h_conv / h_conv[0])**2

# ============================================================
# Plot
# ============================================================

fig, ax = plt.subplots(figsize=(9, 7))

ax.loglog(
    h_conv,
    error_conv,
    "o-",
    color="xkcd:royal blue",
    linewidth=2.5,
    markersize=9,
    label="Numerical RMS Error"
)

ax.loglog(
    h_conv,
    reference,
    "--",
    color="xkcd:dark orange",
    linewidth=2.5,
    label=r"Second-order reference, $O(h^2)$"
)

# Label each point with its resolution
for n, hi, err in zip(N_conv, h_conv, error_conv):
    ax.annotate(
        f"N={n}",
        (hi, err),
        xytext=(7, -12),
        textcoords="offset points",
        fontsize=10
    )

ax.set_xlabel(r"Grid spacing, $h$", fontsize=14)
ax.set_ylabel(r"RMS Error", fontsize=14)

ax.set_title(
    rf"3D Poisson Solver — Grid Convergence ($p={p:.3f}$)",
    fontsize=16
)

ax.grid(True, which="major", linestyle="-", alpha=0.5)
ax.grid(True, which="minor", linestyle=":", alpha=0.25)

ax.legend(fontsize=12)

ax.tick_params(axis="both", which="major", labelsize=12)

plt.tight_layout()
plt.show()