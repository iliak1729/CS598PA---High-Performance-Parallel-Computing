import numpy as np
import matplotlib.pyplot as plt
cases = [
    ("P256",    "256 Cores"),
    ("P192",    "192 Cores"),
    ("P128_N2", "128 Cores 2 Nodes"),
    ("P128",    "128 Cores 1 Node"),
    ("P64",     "64 Cores"),
    ("P8",      "8 Cores"),
]

for folder, plotTitle in cases:
    data = np.loadtxt(f"Homework/HW1/Problem2/cluster_download/HW1P2_RESULTS/{folder}/timing.log", skiprows=1)
    tit = plotTitle

    p = data[:, 0].astype(int)
    nwds = data[:, 1]
    rtt = 0.5*data[:, 4]

    plt.figure()

    for rank in np.unique(p):
        mask = (p == rank)

        if rank == 0:
            plt.loglog(
                nwds[mask],
                rtt[mask],
                'k--',
                label="p = 0"
            )
        else:
            plt.loglog(
                nwds[mask],
                rtt[mask],
                color = 'red'
            )
    # ============================================================
    # Average RTT across all p
    # ============================================================
    unique_nwds = np.unique(nwds)

    avg_rtt = np.array([
        np.mean(rtt[nwds == n])
        for n in unique_nwds
    ])

    # plt.loglog(
    #     unique_nwds,
    #     avg_rtt,
    #     linewidth=1.5,
    #     label="Average",
    #     color = 'blue'
    # )

    plt.title(tit)
    plt.xlabel("Message Size (words)")
    plt.ylabel("1/2 RTT (s)")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()

    # ============================================================
    # Latency
    # ============================================================

    n_small = 5

    latency_rtt = np.mean(avg_rtt[:n_small])
    latency_oneway = latency_rtt / 1.0

    


    # ============================================================
    # Inverse bandwidth
    # ============================================================

    bytes_ = unique_nwds * 8

    # Fit the final 20% of the data
    n_large = max(2, int(0.2 * len(bytes_)))

    m_large = bytes_[-n_large:]
    t_large = avg_rtt[-n_large:]

    beta_rtt, alpha_fit = np.polyfit(m_large, t_large, 1)

    beta_oneway = beta_rtt / 1.0
    bandwidth = 1.0 / beta_oneway

    # ============================================================
    # Find m2 such that t(m2) = 2*t(1)
    # ============================================================

    t1 = avg_rtt[0]
    target_t = 2.0 * t1

    # Find first point where average time reaches/exceeds 2*t(1)
    idx_candidates = np.where(avg_rtt >= target_t)[0]

    if len(idx_candidates) == 0:
        m2 = np.nan
        print(f"m2 not reached in available data")
    else:
        idx = idx_candidates[0]

        if idx == 0:
            m2 = unique_nwds[0]
        else:
            m1_low = unique_nwds[idx - 1]
            m1_high = unique_nwds[idx]

            t_low = avg_rtt[idx - 1]
            t_high = avg_rtt[idx]

            # Linear interpolation
            m2 = m1_low + (
                (target_t - t_low)
                / (t_high - t_low)
            ) * (m1_high - m1_low)

    # ============================================================
    # Estimate eager limit
    # ============================================================

    # Relative change between consecutive average timing points
    relative_jump = np.diff(avg_rtt) / avg_rtt[:-1]

    # Index of largest relative jump
    idx_eager = np.argmax(relative_jump)

    # Eager-limit transition occurs between these two message sizes
    m_before = unique_nwds[idx_eager]
    m_after  = unique_nwds[idx_eager + 1]

    t_before = avg_rtt[idx_eager]
    t_after  = avg_rtt[idx_eager + 1]

    # Use first message size after the jump as estimate
    m_eager = m_after
    print("===========================",tit, "===========================")
    print(f"RTT latency     = {latency_rtt:.6e} s")
    # print(f"One-way latency = {latency_oneway:.6e} s")
    print(f"RTT inverse bandwidth     = {beta_rtt:.6e} s/byte")
    # print(f"One-way inverse bandwidth = {beta_oneway:.6e} s/byte")
    # print(f"Bandwidth                  = {bandwidth:.6e} bytes/s")
    # print(f"Bandwidth                  = {bandwidth / 1e9:.3f} GB/s")
    # print(f"t(1)                      = {t1:.6e} s")
    # print(f"2*t(1)                    = {target_t:.6e} s")
    # print(f"m2 where t(m2)=2*t(1)     = {m2:.3f} words")
    print(f"m2                         = {8*m2:.3f} bytes")

    # print(f"Eager limit estimate        = {m_eager:.0f} words")
    print(f"Eager limit estimate        = {8*m_eager:.0f} bytes")
    # print(f"Timing jump                 = {t_before:.6e} -> {t_after:.6e} s")
    # print(f"Relative timing jump        = {relative_jump[idx_eager]*100:.2f}%")

    # Save figure
    plt.savefig(
        f"./Homework/HW1/Problem2/CorePlot_{tit}.png",
        dpi=300,
        bbox_inches="tight"
    )

plt.show()
