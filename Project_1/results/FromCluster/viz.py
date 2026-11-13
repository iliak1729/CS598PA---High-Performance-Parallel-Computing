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