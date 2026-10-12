#!/usr/bin/env python3
"""Plot strong/weak scaling and performance comparisons for distributed LU.

Usage:
  python plot_lu_scaling.py --blocked lu_results_block.csv --unblocked lu_results_unblocked.csv
  python plot_lu_scaling.py --blocked blocked.csv --unblocked old.csv --bs 64 --outdir figures

Blocked CSV may have either m,n,P,Q,bs,time,gflops or
m,n,P,Q,time,gflops,bs headers; the actual data order is detected.
"""
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt


def read_results(path, blocked=False):
    raw = pd.read_csv(path)
    needed = {'m', 'n', 'P', 'Q', 'time', 'gflops'}
    if not needed.issubset(raw.columns):
        raise ValueError(f'{path}: expected columns {needed}')
    # Some blocked files have a header ending time,gflops,bs while their
    # data rows are actually bs,time,gflops. Detect this via the bs column.
    if blocked:
        if 'bs' not in raw:
            raise ValueError(f'{path}: missing bs column')
        def is_block_column(s):
            x = pd.to_numeric(s, errors='coerce').to_numpy(dtype=float)
            return (np.isfinite(x).all() and (x > 0).all() and
                    np.allclose(x, np.rint(x)) and x.max() <= 4096)
        if not is_block_column(raw['bs']) and is_block_column(raw['time']):
            old_bs = raw['time'].copy()
            raw['time'] = raw['gflops'].copy()
            raw['gflops'] = raw['bs'].copy()
            raw['bs'] = old_bs
            print(f'Corrected mismatched CSV header in {path}')
    for col in needed | ({'bs'} if blocked else set()):
        raw[col] = pd.to_numeric(raw[col], errors='raise')
    raw['procs'] = raw['P'].astype(int) * raw['Q'].astype(int)
    raw['grid'] = raw['P'].astype(int).astype(str) + 'x' + raw['Q'].astype(int).astype(str)
    if (raw['time'] <= 0).any():
        raise ValueError(f'{path}: nonpositive execution times')
    return raw


def plot_save(fig, name, outdir, dpi):
    fig.tight_layout()
    if SAVE_PLOTS:
        fig.savefig(outdir / f'{name}.png', dpi=dpi, bbox_inches='tight')
        fig.savefig(outdir / f'{name}.pdf', bbox_inches='tight')
    if SHOW_PLOTS:
        plt.show()
    plt.close(fig)
    if SAVE_PLOTS:
        print(f'Saved {name}.png and {name}.pdf')


def scaling(df, outdir, dpi, prefix, metric):
    fig, ax = plt.subplots(figsize=(8, 5))
    for n, sub in df.groupby('n'):
        baseline = sub[(sub.P == 1) & (sub.Q == 1)]
        if baseline.empty:
            continue
        t1 = baseline.time.median()
        # For 8 processes prefer 2x4; otherwise choose the fastest grid.
        points = []
        for p, group in sub.groupby('procs'):
            chosen = group[(group.P == 2) & (group.Q == 4)] if p == 8 else group
            if chosen.empty:
                chosen = group
            t = chosen.time.min()
            val = t1 / t if metric == 'speedup' else 100 * t1 / (p * t)
            points.append((p, val))
        points.sort()
        ax.plot([x for x, _ in points], [y for _, y in points], 'o-', label=f'N={int(n)}')
    ps = sorted(df.procs.unique())
    if metric == 'speedup':
        ax.plot(ps, ps, 'k--', linewidth=1.4, label='Ideal')
        ax.set_ylabel('Speedup (T1 / Tp)')
        ax.set_title(f'{prefix}: strong-scaling speedup')
    else:
        ax.axhline(100, color='black', linestyle='--', linewidth=1.4, label='Ideal')
        ax.set_ylabel('Parallel efficiency (%)')
        ax.set_title(f'{prefix}: strong-scaling efficiency')
    ax.set_xlabel('MPI processes')
    ax.set_xticks(ps)
    ax.grid(True, alpha=0.3)
    ax.legend(fontsize=9)
    plot_save(fig, f'{prefix.lower()}_strong_{metric}', outdir, dpi)


def weak_scaling(df, outdir, dpi, prefix):
    # Approximate work-equivalent pairs: N8 ~= 2*N1, since LU work ~ N^3.
    base = df[(df.P == 1) & (df.Q == 1)]
    eight = df[(df.P == 2) & (df.Q == 4)]
    if base.empty or eight.empty:
        return
    pairs = []
    for _, r in base.iterrows():
        candidates = eight.copy()
        candidates['relative_error'] = abs(candidates.n / r.n - 2)
        candidate = candidates.loc[candidates.relative_error.idxmin()]
        if candidate.relative_error > 0.03:
            continue
        efficiency = 100 * r.time / candidate.time
        pairs.append((f'{int(r.n)} → {int(candidate.n)}', efficiency))
    if not pairs:
        return
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.bar([p[0] for p in pairs], [p[1] for p in pairs])
    ax.axhline(100, color='black', linestyle='--', label='Ideal')
    ax.set_ylabel('Approximate weak efficiency (%)')
    ax.set_xlabel('Matrix dimension: 1 process → 8 processes')
    ax.set_title(f'{prefix}: work-based weak scaling (1 vs 8 MPI ranks)')
    ax.grid(True, axis='y', alpha=0.3)
    ax.legend()
    plot_save(fig, f'{prefix.lower()}_weak_efficiency', outdir, dpi)


def grid_comparison(df, outdir, dpi, prefix):
    eight = df[df.procs == 8]
    if eight.empty:
        return
    pivot = eight.pivot_table(index='n', columns='grid', values='gflops', aggfunc='median')
    fig, ax = plt.subplots(figsize=(8, 5))
    for grid in ['2x4', '4x2']:
        if grid in pivot:
            ax.plot(pivot.index, pivot[grid], 'o-', label=grid)
    ax.set_xlabel('Matrix dimension N')
    ax.set_ylabel('GFLOPS')
    ax.set_title(f'{prefix}: 8-process grid orientation')
    ax.grid(True, alpha=0.3)
    ax.legend(title='Processor grid')
    plot_save(fig, f'{prefix.lower()}_grid_orientation', outdir, dpi)


def gflops_vs_n(df, outdir, dpi, prefix):
    fig, ax = plt.subplots(figsize=(8, 5))
    for grid, sub in df.groupby('grid'):
        sub = sub.sort_values('n')
        ax.plot(sub.n, sub.gflops, 'o-', label=grid)
    ax.set_xlabel('Matrix dimension N')
    ax.set_ylabel('GFLOPS')
    ax.set_title(f'{prefix}: GFLOPS vs matrix size')
    ax.grid(True, alpha=0.3)
    ax.legend(title='Processor grid')
    plot_save(fig, f'{prefix.lower()}_gflops_vs_n', outdir, dpi)


def compare(blocked, unblocked, outdir, dpi):
    # Compare approximately equal N, and match processor grids exactly.
    fig, ax = plt.subplots(figsize=(8, 5))
    for label, df in [('Unblocked', unblocked), ('Blocked', blocked)]:
        sub = df[(df.P == 2) & (df.Q == 2)].sort_values('n')
        ax.plot(sub.n, sub.gflops, 'o-', label=label)
    ax.set_xlabel('Matrix dimension N')
    ax.set_ylabel('GFLOPS')
    ax.set_title('Blocked vs unblocked LU (2x2 processor grid)')
    ax.grid(True, alpha=0.3)
    ax.legend()
    plot_save(fig, 'blocked_vs_unblocked_gflops', outdir, dpi)

    fig, ax = plt.subplots(figsize=(8, 5))
    for label, df in [('Unblocked', unblocked), ('Blocked', blocked)]:
        sub = df[df.n == df.n.max()]
        base = sub[(sub.P == 1) & (sub.Q == 1)]
        if base.empty:
            continue
        t1 = base.time.median()
        points = []
        for p, group in sub.groupby('procs'):
            preferred = group[(group.P == 2) & (group.Q == 4)] if p == 8 else group
            if preferred.empty:
                preferred = group
            points.append((p, t1 / preferred.time.min()))
        points.sort()
        ax.plot([x for x, _ in points], [y for _, y in points], 'o-', label=label)
    ps = sorted(set(blocked.procs) | set(unblocked.procs))
    ax.plot(ps, ps, 'k--', label='Ideal')
    ax.set_xticks(ps)
    ax.set_xlabel('MPI processes')
    ax.set_ylabel('Speedup')
    ax.set_title('Blocked vs unblocked: strong scaling at largest N')
    ax.grid(True, alpha=0.3)
    ax.legend()
    plot_save(fig, 'blocked_vs_unblocked_strong_scaling', outdir, dpi)

    # Time speedup from blocking for approximately matched N.
    rows = []
    for _, a in blocked.iterrows():
        matches = unblocked[(unblocked.P == a.P) & (unblocked.Q == a.Q)]
        if matches.empty:
            continue
        b = matches.iloc[(matches.n - a.n).abs().argmin()]
        if abs(a.n - b.n) <= 2:
            rows.append({'n': a.n, 'grid': a.grid, 'speedup': b.time / a.time})
    if rows:
        table = pd.DataFrame(rows).pivot_table(index='n', columns='grid', values='speedup', aggfunc='median')
        fig, ax = plt.subplots(figsize=(8, 5))
        for grid in table.columns:
            ax.plot(table.index, table[grid], 'o-', label=grid)
        ax.axhline(1, color='black', linestyle='--', linewidth=1)
        ax.set_xlabel('Matrix dimension N (blocked version)')
        ax.set_ylabel('Speedup from blocking (T_unblocked / T_blocked)')
        ax.set_title('Benefit of blocking by processor grid')
        ax.grid(True, alpha=0.3)
        ax.legend(title='Processor grid')
        plot_save(fig, 'blocking_speedup_by_grid', outdir, dpi)


# ============================================================
# Configuration — edit these values directly in VS Code
# ============================================================

BLOCKED_FILE = "./Homework/HW3/lu_c_files/lu_results_block_2x2.csv"
UNBLOCKED_FILE = "./Homework/HW3/lu_c_files/lu_results_2x2.csv"
OUTPUT_DIRECTORY = "./Homework/HW3/lu_c_files/LU_Plots_Mac/"
BLOCK_SIZE = 32
SAVE_PLOTS = True
SHOW_PLOTS = False
DPI = 220

# ============================================================
# Load CSV files and prepare data
# ============================================================


def aggregate(df):
    # Median across repeated measurements of the same configuration.
    df = df.groupby(["m", "n", "P", "Q"], as_index=False).agg(
        time=("time", "median"), gflops=("gflops", "median")
    )
    df["procs"] = df.P * df.Q
    df["grid"] = df.P.astype(str) + "x" + df.Q.astype(str)
    return df


output_dir = Path(OUTPUT_DIRECTORY)
output_dir.mkdir(parents=True, exist_ok=True)
blocked_all = read_results(BLOCKED_FILE, blocked=True)
unblocked = aggregate(read_results(UNBLOCKED_FILE))
blocked = aggregate(blocked_all[blocked_all.bs == BLOCK_SIZE].copy())
if blocked.empty:
    raise ValueError(f"No blocked results for bs={BLOCK_SIZE}")

print(f"Loaded {len(blocked_all)} blocked rows and {len(unblocked)} unblocked configurations")
print("Block sizes:", sorted(blocked_all.bs.unique()))
print("Processor grids:", sorted(blocked.grid.unique()))
print("Matrix sizes:", sorted(blocked.n.unique()))

plt.rcParams.update({"font.size": 11, "axes.titlesize": 13, "figure.dpi": 110})

# ============================================================
# Plot 1: Strong-scaling speedup
# ============================================================

scaling(blocked, output_dir, DPI, "Blocked", "speedup")
scaling(unblocked, output_dir, DPI, "Unblocked", "speedup")

# ============================================================
# Plot 2: Strong-scaling parallel efficiency
# ============================================================

scaling(blocked, output_dir, DPI, "Blocked", "efficiency")
scaling(unblocked, output_dir, DPI, "Unblocked", "efficiency")

# ============================================================
# Plot 3: Approximate weak-scaling efficiency
# Work per rank proportional to N^3 / (P*Q)
# ============================================================

weak_scaling(blocked, output_dir, DPI, "Blocked")
weak_scaling(unblocked, output_dir, DPI, "Unblocked")

# ============================================================
# Plot 4: Eight-process grid orientation (2x4 vs 4x2)
# ============================================================

grid_comparison(blocked, output_dir, DPI, "Blocked")
grid_comparison(unblocked, output_dir, DPI, "Unblocked")

# ============================================================
# Plot 5: GFLOPS versus matrix dimension N
# ============================================================

gflops_vs_n(blocked, output_dir, DPI, "Blocked")
gflops_vs_n(unblocked, output_dir, DPI, "Unblocked")

# ============================================================
# Plot 6: Blocked versus unblocked comparisons
# ============================================================

compare(blocked, unblocked, output_dir, DPI)

# ============================================================
# Plot 7: Block-size sweep, GFLOPS versus block size
# ============================================================

for (p, q), grid_data in blocked_all.groupby(["P", "Q"]):
    fig, ax = plt.subplots(figsize=(9, 5.5))
    for n, data in grid_data.groupby("n"):
        curve = data.groupby("bs", as_index=False).gflops.median().sort_values("bs")
        ax.plot(curve.bs, curve.gflops, "o-", label=f"N={n}")
    ax.set_xscale("log", base=2)
    ax.set_xticks(sorted(blocked_all.bs.unique()))
    ax.set_xticklabels([str(int(v)) for v in sorted(blocked_all.bs.unique())])
    ax.set_xlabel("Block size")
    ax.set_ylabel("GFLOPS")
    ax.set_title(f"Blocked LU: block-size sweep ({p}x{q} grid)")
    ax.grid(True, alpha=0.3)
    ax.legend(title="Matrix size")
    plot_save(fig, f"block_sweep_{p}x{q}", output_dir, DPI)

print(f"\nFinished. Plots saved to {output_dir.resolve()}")
