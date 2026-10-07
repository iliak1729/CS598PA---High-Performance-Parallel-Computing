import glob
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
# ============================================================
# Load all timing files
# ============================================================
dataDirectory = "./Homework/HW2/HW2_RESULTS/"
files = sorted(glob.glob(dataDirectory + "timing_P*.log"))
print (f"Found {len(files)} timing files: {files}")
if len(files) == 0:
    raise RuntimeError("No timing_P*.log files found")

# Column definitions:
#
# 0  method
# 1  Nx
# 2  Ny
# 3  P
# 4  n
# 5  n/P
# 6  error
# 7  total
# 8  fst
# 9  transpose
# 10 comm
# 11 divide
# 12 GFLOPS

all_data = []

for filename in files:

    data = np.genfromtxt(
        filename,
        comments="#",
        dtype=None,
        encoding=None
    )

    # If a file contains only one row, make it 1D iterable
    data = np.atleast_1d(data)

    all_data.extend(data)

print(f"Loaded {len(all_data)} benchmark cases from {len(files)} files.")

# ============================================================
# Convert into arrays
# ============================================================

method = np.array([row[0] for row in all_data])

Nx = np.array([row[1] for row in all_data], dtype=int)
Ny = np.array([row[2] for row in all_data], dtype=int)
P  = np.array([row[3] for row in all_data], dtype=int)

n          = np.array([row[4]  for row in all_data], dtype=float)
n_per_rank = np.array([row[5]  for row in all_data], dtype=float)
error      = np.array([row[6]  for row in all_data], dtype=float)

total     = np.array([row[7]  for row in all_data], dtype=float)
fst       = np.array([row[8]  for row in all_data], dtype=float)
transpose = np.array([row[9]  for row in all_data], dtype=float)
comm      = np.array([row[10] for row in all_data], dtype=float)
divide    = np.array([row[11] for row in all_data], dtype=float)

gflops = np.array([row[12] for row in all_data], dtype=float)

# ============================================================
# Custom legend
# ============================================================

def add_plot_legend(ax,loc1="upper left",loc2="upper right"):

    # Grid-size legend: color represents N
    grid_handles = [
        Line2D(
            [0], [0],
            color=N_colors[N],
            linewidth=2,
            label=f"N={N}"
        )
        for N in N_unique
    ]

    # Method legend: line style represents method
    method_handles = [
        Line2D(
            [0], [0],
            color="black",
            linestyle="-",
            linewidth=2,
            label="Dealer"
        ),
        Line2D(
            [0], [0],
            color="black",
            linestyle="--",
            linewidth=2,
            label="Crystal"
        )
    ]

    # First legend
    legend_grid = ax.legend(
        handles=grid_handles,
        title="Grid Size",
        loc=loc1
    )

    # Keep first legend when adding second
    ax.add_artist(legend_grid)

    # Second legend
    ax.legend(
        handles=method_handles,
        title="Method",
        loc=loc2
    )

# ============================================================
# Print what was loaded
# ============================================================

print("Processor counts:", np.unique(P))
print("Grid sizes:", np.unique(Nx))
print("Methods:", np.unique(method))
 # ============================================================
# Plot styling
# ============================================================

N_unique = np.sort(np.unique(Nx))

colors = plt.cm.viridis(np.linspace(0, 1, len(N_unique)))

N_colors = {
    N: colors[i]
    for i, N in enumerate(N_unique)
}

method_styles = {
    "dealer": "-",
    "crystal": "--"
}



#=============================================================  PLOTS FROM HERE
# ============================================================
# Plot: Timing Breakdown
# ============================================================

N_target = 8192
P_target = [1, 4, 16, 64]

labels = []
fst_bar = []
transpose_local_bar = []
comm_bar = []
divide_bar = []

for p in P_target:

    for m in ["dealer", "crystal"]:

        mask = (
            (Nx == N_target) &
            (P == p) &
            (method == m)
        )

        if not np.any(mask):
            continue

        labels.append(f"P={p}\n{m.capitalize()}")

        fst_val = fst[mask][0]
        transpose_val = transpose[mask][0]
        comm_val = comm[mask][0]
        divide_val = divide[mask][0]

        fst_bar.append(fst_val)
        transpose_local_bar.append(
            max(transpose_val - comm_val, 0.0)
        )
        comm_bar.append(comm_val)
        divide_bar.append(divide_val)


# Convert to arrays
fst_bar = np.array(fst_bar)
transpose_local_bar = np.array(transpose_local_bar)
comm_bar = np.array(comm_bar)
divide_bar = np.array(divide_bar)

x = np.arange(len(labels))


# ============================================================
# Plot
# ============================================================

plt.figure(figsize=(10, 6))

plt.bar(
    x,
    fst_bar,
    label="FST"
)

plt.bar(
    x,
    transpose_local_bar,
    bottom=fst_bar,
    label="Transpose (Local)"
)

plt.bar(
    x,
    comm_bar,
    bottom=fst_bar + transpose_local_bar,
    label="Communication"
)

plt.bar(
    x,
    divide_bar,
    bottom=fst_bar + transpose_local_bar + comm_bar,
    label="Eigenvalue Division"
)


# ============================================================
# Formatting
# ============================================================

plt.xticks(x, labels)

plt.xlabel("Processor Count and Transpose Method")
plt.ylabel("Time [s]")

plt.title(
    rf"Poisson Solver Timing Breakdown, $N={N_target}$"
)

plt.grid(
    True,
    axis="y",
    alpha=0.3
)

plt.legend()

plt.tight_layout()
plt.savefig("Homework/HW2/Plots/Timing_Breakdown.pdf", bbox_inches="tight")
plt.show()





# # ============================================================
# # Plot 1: Error convergence for all runs
# # ============================================================

# plt.figure()

# # Plot a separate curve for every method and processor count
# P_unique = np.sort(np.unique(P))

# # Line thicknesses from thickest to thinnest
# line_widths = np.linspace(10.0, 1.0, len(P_unique))

# for m in np.unique(method):

#     for i, p in enumerate(np.unique(P)):

#         mask = (method == m) & (P == p)

#         if not np.any(mask):
#             continue

#         # Sort by grid resolution
#         order = np.argsort(Nx[mask])

#         N_plot = Nx[mask][order]
#         error_plot = error[mask][order]

#         plt.loglog(
#             N_plot,
#             error_plot,
#             marker="o",
#             linewidth=line_widths[i],
#             label=f"{m}, P={p}"
#         )


# # ============================================================
# # O(h^2) reference curve
# # ============================================================

# N_reference = np.sort(np.unique(Nx))

# # Pick the error from the smallest available grid
# N0 = N_reference[0]
# error0 = error[Nx == N0][0]

# reference = error0 * (N0 / N_reference)**2

# plt.loglog(
#     N_reference,
#     reference,
#     "k--",
#     linewidth=2,
#     label=r"$O(h^2)$"
# )


# # ============================================================
# # Formatting
# # ============================================================

# plt.xlabel(r"Grid Resolution $N$")
# plt.ylabel(r"$L_\infty$ Error")
# plt.title("Poisson Solver Grid Convergence")

# plt.grid(True, which="both")
# plt.legend()

# plt.tight_layout()
# plt.savefig("Homework/HW2/Plots/Convergence.pdf", bbox_inches="tight")
# plt.show()


# # ============================================================
# # Plot 2: Execution time vs processor count
# # Color = grid size
# # Line style = transpose method
# # ============================================================

# plt.figure()

# for N in N_unique:

#     for m in np.unique(method):

#         mask = (Nx == N) & (method == m)

#         if not np.any(mask):
#             continue

#         order = np.argsort(P[mask])

#         x = P[mask][order]
#         y = total[mask][order]

#         plt.loglog(
#             x,
#             y,
#             marker="o",
#             color=N_colors[N],
#             linestyle=method_styles[m],
#             linewidth=2,
#             label=f"N={N}, {m.capitalize()}"
#         )

# plt.xticks(
#     P_unique,
#     [str(p) for p in P_unique]
# )

# plt.xlabel("Number of Processors, P")
# plt.ylabel("Execution Time [s]")
# plt.title("Poisson Solver Execution Time")

# plt.grid(True, which="both")
# add_plot_legend(plt.gca())

# plt.tight_layout()
# plt.savefig("Homework/HW2/Plots/Execution_Time.pdf", bbox_inches="tight")
# plt.show()



# # ============================================================
# # Plot 3: Local FST time vs P and N and M
# # ============================================================

# # ============================================================
# # Plot 3a: Local FST time vs P
# # Color = global grid size N
# # Dealer/crystal FST times averaged
# # ============================================================

# plt.figure()

# for N in N_unique:

#     P_N = np.sort(np.unique(P[Nx == N]))

#     P_plot = []
#     fst_plot = []

#     for p in P_N:

#         mask = (Nx == N) & (P == p)

#         if not np.any(mask):
#             continue

#         # Average dealer and crystal FST measurements
#         fst_avg = np.mean(fst[mask])

#         P_plot.append(p)
#         fst_plot.append(fst_avg)

#     plt.loglog(
#         P_plot,
#         fst_plot,
#         marker="o",
#         color=N_colors[N],
#         linewidth=2,
#         label=f"N={N}"
#     )


# plt.xticks(
#     P_unique,
#     [str(p) for p in P_unique]
# )

# plt.xlabel(r"Number of Processors, $P$")
# plt.ylabel("Local FST Time [s]")
# plt.title("Local FST Time vs Processor Count")

# plt.grid(True, which="both")
# plt.legend(title="Grid Size",loc="upper right")

# plt.tight_layout()
# plt.savefig("Homework/HW2/Plots/LocalFSTTimeVsP.pdf", bbox_inches="tight")
# plt.show()


# # ============================================================
# # Plot 3b: Local FST time vs M = n/P
# # Color = global grid size N
# # Dealer/crystal FST times averaged
# # ============================================================

# plt.figure()

# for N in N_unique:

#     M_plot = []
#     fst_plot = []

#     P_N = np.sort(np.unique(P[Nx == N]))

#     for p in P_N:

#         mask = (Nx == N) & (P == p)

#         if not np.any(mask):
#             continue

#         # Actual local number of unknowns per processor
#         M = np.mean(n_per_rank[mask])

#         # Average dealer and crystal FST measurements
#         fst_avg = np.mean(fst[mask])

#         M_plot.append(M)
#         fst_plot.append(fst_avg)

#     M_plot = np.array(M_plot)
#     fst_plot = np.array(fst_plot)

#     # Sort by local problem size
#     order = np.argsort(M_plot)

#     plt.loglog(
#         M_plot[order],
#         fst_plot[order],
#         marker="o",
#         color=N_colors[N],
#         linewidth=2,
#         label=f"N={N}"
#     )

# plt.xlabel(r"Local Problem Size, $M=n/P$")
# plt.ylabel("Local FST Time [s]")
# plt.title(r"Local FST Time vs Local Problem Size")

# plt.grid(True, which="both")
# plt.legend(title="Grid Size")

# plt.tight_layout()
# plt.savefig("Homework/HW2/Plots/LocalFSTTimeVsM.pdf", bbox_inches="tight")
# plt.show()


# # ============================================================
# # Plot 4: Communication time vs P and N and M
# # ============================================================

# # ============================================================
# # Plot 4a: Communication time vs P
# # Color = global grid size N
# # Line style = communication method
# # ============================================================

# plt.figure()

# for N in N_unique:

#     for m in np.unique(method):

#         mask = (Nx == N) & (method == m)

#         if not np.any(mask):
#             continue

#         order = np.argsort(P[mask])

#         x = P[mask][order]
#         y = comm[mask][order]

#         plt.loglog(
#             x,
#             y,
#             marker="o",
#             color=N_colors[N],
#             linestyle=method_styles[m],
#             linewidth=2
#         )

# plt.xticks(
#     P_unique,
#     [str(p) for p in P_unique]
# )

# plt.xlabel(r"Number of Processors, $P$")
# plt.ylabel("Communication Time [s]")
# plt.title("Communication Time vs Processor Count")

# plt.grid(True, which="both")

# add_plot_legend(plt.gca())

# plt.tight_layout()
# plt.savefig("Homework/HW2/Plots/CommunicationTimeVsP.pdf", bbox_inches="tight")
# plt.show()

# # ============================================================
# # Plot 4b: Communication time vs M = n/P
# # Color = global grid size N
# # Line style = communication method
# # ============================================================

# plt.figure()

# for N in N_unique:

#     for m in np.unique(method):

#         mask = (Nx == N) & (method == m)

#         if not np.any(mask):
#             continue

#         M_plot = n_per_rank[mask]
#         comm_plot = comm[mask]

#         # Sort by M
#         order = np.argsort(M_plot)

#         M_plot = M_plot[order]
#         comm_plot = comm_plot[order]

#         plt.loglog(
#             M_plot,
#             comm_plot,
#             marker="o",
#             color=N_colors[N],
#             linestyle=method_styles[m],
#             linewidth=2
#         )

# plt.xlabel(r"Local Problem Size, $M=n/P$")
# plt.ylabel("Communication Time [s]")
# plt.title("Communication Time vs Local Problem Size")

# plt.grid(True, which="both")

# add_plot_legend(plt.gca(),loc2="lower right")

# plt.tight_layout()
# plt.savefig("Homework/HW2/Plots/CommunicationTimeVsM.pdf", bbox_inches="tight")
# plt.show()

# # ============================================================
# # Plot 5: GFLOPS vs P
# # ============================================================
# # ============================================================
# # Plot 5: GFLOPS vs P
# # Color = global grid size N
# # Line style = communication method
# # ============================================================

# plt.figure()

# for N in N_unique:

#     for m in np.unique(method):

#         mask = (Nx == N) & (method == m)

#         if not np.any(mask):
#             continue

#         order = np.argsort(P[mask])

#         P_plot = P[mask][order]
#         gflops_plot = gflops[mask][order]

#         plt.plot(
#             P_plot,
#             gflops_plot,
#             marker="o",
#             color=N_colors[N],
#             linestyle=method_styles[m],
#             linewidth=2
#         )


# # ============================================================
# # Formatting
# # ============================================================

# plt.xscale("log", base=2)

# plt.xticks(
#     P_unique,
#     [str(p) for p in P_unique]
# )

# plt.xlabel(r"Number of Processors, $P$")
# plt.ylabel("GFLOPS")
# plt.title("Poisson Solver Performance (GFLOPS vs P)")

# plt.grid(True)

# add_plot_legend(plt.gca())
# plt.tight_layout()
# plt.savefig("Homework/HW2/Plots/GFLOPSVsP.pdf", bbox_inches="tight")
# plt.show()

# # ============================================================
# # Plot 6: GFLOPS vs n for Single Processor
# # ============================================================

# plt.figure()

# for m in np.unique(method):

#     # Single-processor runs only
#     mask = (P == 1) & (method == m)

#     if not np.any(mask):
#         continue

#     order = np.argsort(n[mask])

#     n_plot = n[mask][order]
#     gflops_plot = gflops[mask][order]

#     plt.semilogx(
#         n_plot,
#         gflops_plot,
#         marker="o",
#         linestyle=method_styles[m],
#         linewidth=2,
#         label=m.capitalize()
#     )


# # ============================================================
# # Formatting
# # ============================================================

# plt.xlabel(r"Problem Size, $n$")
# plt.ylabel("GFLOPS")
# plt.title("Single-Processor Poisson Solver Performance")

# plt.grid(True, which="both")
# plt.legend(title="Method")

# plt.tight_layout()
# plt.savefig("Homework/HW2/Plots/GFLOPSVsNSingleCore.pdf", bbox_inches="tight")
# plt.show()


# # ============================================================
# # Plot 7: Parallel Efficiency vs n/P for all n 
# # ============================================================
# # ============================================================
# # Plot 7: Parallel Efficiency vs n/P for all n
# # Color = global grid size N
# # Line style = communication method
# # ============================================================

# plt.figure()

# for N in N_unique:

#     for m in np.unique(method):

#         # ----------------------------------------------------
#         # Find single-processor baseline for this N and method
#         # ----------------------------------------------------
#         baseline_mask = (
#             (Nx == N) &
#             (method == m) &
#             (P == 1)
#         )

#         if not np.any(baseline_mask):
#             continue

#         T1 = total[baseline_mask][0]

#         # ----------------------------------------------------
#         # Get all processor counts for this N and method
#         # ----------------------------------------------------
#         mask = (
#             (Nx == N) &
#             (method == m)
#         )

#         if not np.any(mask):
#             continue

#         P_data = P[mask]
#         T_data = total[mask]
#         M_data = n_per_rank[mask]

#         # Parallel efficiency
#         efficiency = T1 / (P_data * T_data)

#         # Sort by n/P
#         order = np.argsort(M_data)

#         plt.semilogx(
#             M_data[order],
#             efficiency[order],
#             marker="o",
#             color=N_colors[N],
#             linestyle=method_styles[m],
#             linewidth=2
#         )


# # ============================================================
# # 80% Efficiency Reference
# # ============================================================

# plt.axhline(
#     0.8,
#     color="black",
#     linestyle=":",
#     linewidth=1.5,
#     label="80% Efficiency"
# )


# # ============================================================
# # Formatting
# # ============================================================

# plt.xlabel(r"Local Problem Size, $n/P$")
# plt.ylabel(r"Parallel Efficiency, $E_P$")
# plt.title(r"Parallel Efficiency vs Local Problem Size")

# plt.ylim(0, 3.5)

# plt.grid(True, which="both")

# add_plot_legend(plt.gca())

# plt.tight_layout()
# plt.savefig("Homework/HW2/Plots/ParallelEfficiencyVsM.pdf", bbox_inches="tight")
# plt.show()
