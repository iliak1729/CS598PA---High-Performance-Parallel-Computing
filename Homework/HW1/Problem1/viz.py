import numpy as np
import matplotlib.pyplot as plt

# ============================================================
# Select which attempts to plot
# ============================================================
attempts = [5]

# Available markers
markers = ['o', 's', '^', 'v', 'D', 'p']

plt.figure()

# ============================================================
# C implementation attempts
# ============================================================
for attempt in attempts:

    # Build filename
    filename = (
        f"Homework/HW1/Problem1/c_implementation/"
        f"Attempt{attempt}/benchmark.log"
    )

    # Load data
    data = np.loadtxt(filename)

    N = data[:, 0]
    gflops = data[:, 2]

    # Find maximum performance
    imax = np.argmax(gflops)

    print(
        f"Maximum GFLOPS for Attempt {attempt}: "
        f"{gflops[imax]:.6f} at N = {N[imax]:.0f}"
    )

    # Plot
    plt.plot(
        N,
        gflops,
        marker=markers[(attempt - 1) % len(markers)],
        label=f"Attempt {attempt}"
    )

# ============================================================
# MATLAB benchmark
# ============================================================
matlab_filename = "Homework/HW1/Problem1/matlab_benchmark.log"

matlab_data = np.loadtxt(matlab_filename)

N_matlab = matlab_data[:, 0]
gflops_matlab = matlab_data[:, 2]

# Find maximum MATLAB performance
imax = np.argmax(gflops_matlab)

print(
    f"Maximum GFLOPS for MATLAB: "
    f"{gflops_matlab[imax]:.6f} at N = {N_matlab[imax]:.0f}"
)

# Always plot MATLAB benchmark
plt.plot(
    N_matlab,
    gflops_matlab,
    marker='x',
    linestyle='--',
    label="MATLAB"
)

# ============================================================
# Plot formatting
# ============================================================
plt.xlabel("Matrix Size, N")
plt.ylabel("Performance (GFLOPS)")

plt.legend()
plt.grid(True)
plt.tight_layout()

# Save figure
attempt_string = ''.join(str(attempt) for attempt in attempts)
output_filename = f"./Homework/HW1/Problem1/speedPlot_{attempt_string}.png"

plt.savefig(output_filename, dpi=300, bbox_inches="tight")

print(f"Figure saved as: {output_filename}")

plt.show()

plt.show()