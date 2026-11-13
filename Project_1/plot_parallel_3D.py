import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

# ============================================================
# Data location and plot settings
# ============================================================
# Always locate results relative to THIS file, not VS Code's
# working directory. Place this script inside Project_1/.
project_dir = Path(__file__).resolve().parent
data_directory = project_dir / 'results' / 'parallel_3D'
data_file = data_directory / 'convergence.csv'

SAVE_PLOTS = True
SHOW_PLOTS = True

if not data_file.is_file():
    raise FileNotFoundError(
        f'Cannot find {data_file}\n'
        'Run run_all_parallel_3D.sh from Project_1 first, or change data_directory above.'
    )

data = pd.read_csv(data_file)
if 'status' in data.columns:
    data = data[data['status'].astype(str).str.strip().str.lower() == 'ok'].copy()

required = ['N', 'h', 'ranks', 'Px', 'Py', 'Pz', 'rms_error', 'solve_time_s']
missing = [name for name in required if name not in data.columns]
if missing:
    raise ValueError(f'Missing CSV columns: {missing}')

for name in required:
    data[name] = pd.to_numeric(data[name], errors='coerce')
data = data.dropna(subset=required)
if data.empty:
    raise ValueError('No successful simulations with valid numeric data in the CSV.')

data['layout'] = (
    data['ranks'].astype(int).astype(str) + ' ranks (' +
    data['Px'].astype(int).astype(str) + 'x' +
    data['Py'].astype(int).astype(str) + 'x' +
    data['Pz'].astype(int).astype(str) + ')'
)

layouts = data['layout'].unique()
colors = plt.cm.viridis(np.linspace(0, 0.85, len(layouts)))
layout_colors = dict(zip(layouts, colors))


def finish_plot(fig, filename):
    fig.tight_layout()
    if SAVE_PLOTS:
        fig.savefig(data_directory / f'{filename}.png', dpi=300, bbox_inches='tight')
        fig.savefig(data_directory / f'{filename}.pdf', bbox_inches='tight')
    if SHOW_PLOTS:
        plt.show()
    else:
        plt.close(fig)


# ============================================================
# Plot 1: Spatial convergence (RMS error vs grid spacing)
# ============================================================
fig, ax = plt.subplots(figsize=(10, 6))

for layout in layouts:
    subset = data[data['layout'] == layout].sort_values('h')
    subset = subset[(subset['h'] > 0) & (subset['rms_error'] > 0)]
    if subset.empty:
        continue
    # Average repeated measurements at the same resolution.
    subset = subset.groupby('h', as_index=False)['rms_error'].mean()
    ax.loglog(subset['h'], subset['rms_error'], 'o-', linewidth=2,
              markersize=6, color=layout_colors[layout], label=layout)

reference = data[(data['h'] > 0) & (data['rms_error'] > 0)].sort_values('h', ascending=False)
if not reference.empty:
    h_ref = float(reference.iloc[0]['h'])
    e_ref = float(reference.iloc[0]['rms_error'])
    h_values = np.sort(reference['h'].unique())
    ax.loglog(h_values, e_ref * (h_values / h_ref)**2,
              'k--', linewidth=2, label='Second-order reference')

ax.set_xlabel('Grid spacing h')
ax.set_ylabel('RMS error')
ax.set_title('3D Poisson: Spatial Convergence')
ax.grid(True, which='both', alpha=0.3)
ax.legend(loc='best', fontsize=9)
finish_plot(fig, 'convergence')


# ============================================================
# Plot 2: Solver time vs global grid resolution
# ============================================================
fig, ax = plt.subplots(figsize=(10, 6))

for layout in layouts:
    subset = data[(data['layout'] == layout) & (data['solve_time_s'] > 0)]
    subset = subset.groupby('N', as_index=False)['solve_time_s'].mean().sort_values('N')
    ax.loglog(subset['N'], subset['solve_time_s'], 'o-', linewidth=2,
              markersize=6, color=layout_colors[layout], label=layout)

n_values = np.sort(data['N'].unique())
ax.set_xticks(n_values)
ax.set_xticklabels([str(int(n)) for n in n_values])
ax.set_xlabel('Global grid resolution N (N x N x N)')
ax.set_ylabel('Solver time (s)')
ax.set_title('3D Poisson: Solver Time')
ax.grid(True, which='both', alpha=0.3)
ax.legend(loc='best', fontsize=9)
finish_plot(fig, 'timing')


# ============================================================
# Plot 3: Strong scaling (speedup vs MPI ranks)
# ============================================================
fig, ax = plt.subplots(figsize=(10, 6))

n_values = np.sort(data['N'].unique())
n_colors = plt.cm.plasma(np.linspace(0, 0.85, len(n_values)))
max_rank = int(data['ranks'].max())

for i, N in enumerate(n_values):
    subset = data[(data['N'] == N) & (data['solve_time_s'] > 0)]
    baseline = subset[subset['ranks'] == 1]
    if baseline.empty:
        print(f'Skipping strong scaling for N={int(N)}: no 1-rank baseline')
        continue
    t1 = baseline['solve_time_s'].mean()
    # Average different decompositions with the same rank count.
    times = subset.groupby('ranks', as_index=False)['solve_time_s'].mean().sort_values('ranks')
    speedup = t1 / times['solve_time_s']
    ax.plot(times['ranks'], speedup, 'o-', linewidth=2, markersize=6,
            color=n_colors[i], label=f'N={int(N)}')

ax.plot([1, max_rank], [1, max_rank], 'k--', linewidth=2, label='Ideal speedup')
ax.set_xlabel('MPI ranks')
ax.set_ylabel('Speedup = T(1) / T(P)')
ax.set_title('3D Poisson: Strong Scaling')
ax.set_xticks(np.sort(data['ranks'].unique()))
ax.grid(True, alpha=0.3)
ax.legend(loc='best', fontsize=9)
finish_plot(fig, 'strong_scaling')


# ============================================================
# Plot 4: Parallel efficiency vs MPI ranks
# ============================================================
fig, ax = plt.subplots(figsize=(10, 6))

for i, N in enumerate(n_values):
    subset = data[(data['N'] == N) & (data['solve_time_s'] > 0)]
    baseline = subset[subset['ranks'] == 1]
    if baseline.empty:
        continue
    t1 = baseline['solve_time_s'].mean()
    times = subset.groupby('ranks', as_index=False)['solve_time_s'].mean().sort_values('ranks')
    efficiency = t1 / (times['ranks'] * times['solve_time_s'])
    ax.plot(times['ranks'], efficiency, 'o-', linewidth=2, markersize=6,
            color=n_colors[i], label=f'N={int(N)}')

ax.axhline(1.0, color='black', linestyle='--', linewidth=2, label='Ideal efficiency')
ax.set_xlabel('MPI ranks')
ax.set_ylabel('Parallel efficiency = T(1) / (P T(P))')
ax.set_title('3D Poisson: Parallel Efficiency')
ax.set_xticks(np.sort(data['ranks'].unique()))
ax.grid(True, alpha=0.3)
ax.legend(loc='best', fontsize=9)
finish_plot(fig, 'parallel_efficiency')

print(f'Finished plotting results from: {data_file}')
