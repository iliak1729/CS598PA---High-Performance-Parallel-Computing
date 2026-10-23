
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>
#include "msg.h"

#define Aij(a, ld, i, j) ((a)[(size_t)(i) + (size_t)(ld) * (size_t)(j)])

typedef struct
{
    // ============================================================
    // MPI Information
    // ============================================================
    int rank;   // Current MPI rank
    int nprocs; // Total number of MPI ranks

    // ============================================================
    // Global Problem
    // ============================================================
    int n; // Total number of unknowns
    int L;
    double dx;    // Grid Spacing
    double TL;    // Left BC
    double TR;    // Right BC
    double alpha; // Heat Source
    // ============================================================
    // Local Problem
    // ============================================================
    int nloc;  // Number of local interior unknowns
    int start; // First global interior index
    int end;   // Last global interior index

} Simulation;

static double cpu_time(void)
{
    return (double)clock() / (double)CLOCKS_PER_SEC;
}

static void init(double *a, double *b,
                 double *c, double *l, double *u,
                 double *S, double *f, double *fs,
                 Simulation *data)
{

    // Construct - NOT CURRENTLY SPD. MAY CAUSE ISSUES. CHECK
    // ============================================================
    // MAIN LOOP (AI)
    // ============================================================
    for (int i = 0; i < data->nloc; ++i)
    {
        // Main Diagonal
        a[i] = -2.0;
        // Off Diagonals
        b[i] = 0.0;
        c[i] = 0.0;
        if (i < data->nloc - 1)
        {
            b[i] = 1.0;
        }
        if (i > 0)
        {
            c[i] = 1.0;
        }
        // Zero off other stuff
        Aij(l, 2, 0, i) = 0.0;
        Aij(l, 2, 1, i) = 0.0;
        Aij(u, data->nloc, i, 0) = 0.0;
        Aij(u, data->nloc, i, 1) = 0.0;
        // RHS
        double x = (data->start + i + 1) * data->dx;
        f[i] = -data->alpha * data->dx * data->dx * sin(M_PI * x / data->L);
    }
    // ============================================================
    // BOTTOM BLOCK (L)
    // ============================================================
    if (data->rank > 0)
    {
        Aij(l, 2, 0, 0) = 1.0;
    }

    if (data->rank < data->nprocs - 1)
    {
        Aij(l, 2, 1, data->nloc - 1) = 1.0;
    }

    // ============================================================
    // RIGHT BLOCK (U)
    // ============================================================
    if (data->rank > 0)
    {
        Aij(u, data->nloc, 0, 0) = 1.0;
    }

    if (data->rank < data->nprocs - 1)
    {
        Aij(u, data->nloc, data->nloc - 1, 1) = 1.0;
    }
    // ============================================================
    // SCHUR COMPLEMENT (S)
    // ============================================================
    Aij(S, 2, 0, 0) = 0.0;
    Aij(S, 2, 1, 0) = 0.0;
    Aij(S, 2, 0, 1) = 0.0;
    Aij(S, 2, 1, 1) = 0.0;
    if (data->rank < data->nprocs - 1)
    {
        printf("Hello World from rank %d!\n", data->rank);
        Aij(S, 2, 1, 1) = -2.0;
    }
    // ============================================================
    // RHS
    // ============================================================
    if (data->rank == 0)
    {
        f[0] = f[0] - data->TL;
    }
    if (data->rank == data->nprocs - 1)
    {
        f[data->nloc - 1] = f[data->nloc - 1] - data->TR;
    }
    fs[0] = 0.0;
    fs[1] = 0.0;
    if (data->rank < data->nprocs - 1)
    {
        // Global index of the separator to the right
        int gi = data->end + 1;

        // Physical coordinate of the separator
        double x = (gi + 1) * data->dx;

        // Sinusoidal source term
        fs[1] = -data->alpha * data->dx * data->dx * sin(M_PI * x / data->L);
    }
}

static void local_elim(double *a, double *b, double *c,
                       double *l, double *u, double *S,
                       double *f, double *fs,
                       Simulation *data)
{
    // a = main diagonal
    // b = super diagonal
    // c = subdiagonal
    // l = lower block
    // u = right block
    // S = schur complement
    // f = interior RHS
    // fs = separator RHS values
    for (int k = 0; k < data->nloc - 1; ++k)
    {
        double pinv = 1.0 / a[k];
        c[k + 1] = pinv * c[k + 1];
        a[k + 1] = a[k + 1] - c[k + 1] * b[k];
        f[k + 1] = f[k + 1] - c[k + 1] * f[k];
        Aij(u, data->nloc, k + 1, 0) = Aij(u, data->nloc, k + 1, 0) - c[k + 1] * Aij(u, data->nloc, k, 0);
        Aij(l, 2, 0, k) = pinv * Aij(l, 2, 0, k);
        Aij(l, 2, 0, k + 1) = Aij(l, 2, 0, k + 1) - Aij(l, 2, 0, k) * b[k];
        Aij(S, 2, 0, 0) = Aij(S, 2, 0, 0) - Aij(l, 2, 0, k) * Aij(u, data->nloc, k, 0);
        fs[0] = fs[0] - Aij(l, 2, 0, k) * f[k];
    }
    // Schurr Complement Update
    Aij(l, 2, 0, data->nloc - 1) = Aij(l, 2, 0, data->nloc - 1) / a[data->nloc - 1];
    Aij(l, 2, 1, data->nloc - 1) = Aij(l, 2, 1, data->nloc - 1) / a[data->nloc - 1];
    // f/fs update
    fs[0] = fs[0] - Aij(l, 2, 0, data->nloc - 1) * f[data->nloc - 1];
    fs[1] = fs[1] - Aij(l, 2, 1, data->nloc - 1) * f[data->nloc - 1];
    // S Update
    Aij(S, 2, 0, 0) = Aij(S, 2, 0, 0) - Aij(l, 2, 0, data->nloc - 1) * Aij(u, data->nloc, data->nloc - 1, 0);
    Aij(S, 2, 0, 1) = Aij(S, 2, 0, 1) - Aij(l, 2, 0, data->nloc - 1) * Aij(u, data->nloc, data->nloc - 1, 1);
    Aij(S, 2, 1, 0) = Aij(S, 2, 1, 0) - Aij(l, 2, 1, data->nloc - 1) * Aij(u, data->nloc, data->nloc - 1, 0);
    Aij(S, 2, 1, 1) = Aij(S, 2, 1, 1) - Aij(l, 2, 1, data->nloc - 1) * Aij(u, data->nloc, data->nloc - 1, 1);
}
static void construct_schur(double *S, double *fs, double *sa,
                            double *sb, double *sc, double *sf,
                            Simulation *data)
{
    // S = local schur
    // fs = local separator values
    // sa = global schur main diagonal
    // sb = global schur super diagonal
    // sc = global schur sub diagonal
    // sf = global schur RHS
    int p = data->rank;
    int nsep = data->nprocs - 1;
    if (nsep == 0)
        return;
    // Set initial conditions
    for (int i = 0; i < nsep; ++i)
    {
        sa[i] = 0.0;
        sb[i] = 0.0;
        sc[i] = 0.0;
        sf[i] = 0.0;
    }
    // Left Separator communication setup
    if (p > 0)
    {
        sa[p - 1] += Aij(S, 2, 0, 0);
        sf[p - 1] += fs[0];
    }
    // Right Separator communication Setup
    if (p < data->nprocs - 1)
    {
        sa[p] += Aij(S, 2, 1, 1);
        sf[p] += fs[1];
    }
    // Off diagonals only on non-boundary ranks
    if (p > 0 && p < data->nprocs - 1)
    {
        sb[p - 1] += Aij(S, 2, 0, 1);
        sc[p] += Aij(S, 2, 1, 0);
    }

    // Now we need to do sums
    double *tmp = malloc(nsep * sizeof(*tmp));

    gsum_double(sa, tmp, nsep);
    for (int i = 0; i < nsep; ++i)
        sa[i] = tmp[i];

    gsum_double(sb, tmp, nsep);
    for (int i = 0; i < nsep; ++i)
        sb[i] = tmp[i];

    gsum_double(sc, tmp, nsep);
    for (int i = 0; i < nsep; ++i)
        sc[i] = tmp[i];

    gsum_double(sf, tmp, nsep);
    for (int i = 0; i < nsep; ++i)
        sf[i] = tmp[i];

    free(tmp);
}

static void backsolve(double *a, double *b,
                      double *f, double *u, int n)
{
    // This is a normal backsubstitute method,
    // and assumes that c has already been zerod out.
    if (n == 0)
        return;

    u[n - 1] = f[n - 1] / a[n - 1];
    for (int i = n - 2; i >= 0; --i)
    {
        u[i] = (f[i] - b[i] * u[i + 1]) / a[i];
    }
}
static void solve_schur(double *sa, double *sb, double *sc,
                        double *sf, double *us, Simulation *data)
{
    int nsep = data->nprocs - 1;

    if (nsep == 0)
        return;
    // Forward Pass
    for (int k = 0; k < nsep - 1; ++k)
    {
        double pinv = 1.0 / sa[k];

        sc[k + 1] = pinv * sc[k + 1];
        sa[k + 1] = sa[k + 1] - sc[k + 1] * sb[k];
        sf[k + 1] = sf[k + 1] - sc[k + 1] * sf[k];
    }

    // Backwards Pass
    backsolve(sa, sb, sf, us, nsep);
}

static double *gather_matrix(const double *a,
                             const double *b,
                             const double *c,
                             const double *l,
                             const double *u,
                             const double *S,
                             const Simulation *data)
{
    int rank = data->rank;
    int nprocs = data->nprocs;
    int N = data->n;

    double *global_a = NULL;

    // ============================================================
    // ALLOCATE GLOBAL MATRIX
    // ============================================================
    if (rank == 0)
    {
        global_a = calloc((size_t)N * N, sizeof(double));
    }

    // ============================================================
    // SEND LOCAL MATRICES
    // ============================================================
    if (rank != 0)
    {
        isend(0, a, data->nloc * sizeof(double), 400);
        isend(0, b, data->nloc * sizeof(double), 401);
        isend(0, c, data->nloc * sizeof(double), 402);

        isend(0, l, 2 * data->nloc * sizeof(double), 403);
        isend(0, u, 2 * data->nloc * sizeof(double), 404);
        isend(0, S, 4 * sizeof(double), 405);

        msgwait();
        return NULL;
    }

    // ============================================================
    // RECONSTRUCT GLOBAL MATRIX
    // ============================================================
    int nInterior = N - (nprocs - 1);
    int base = nInterior / nprocs;
    int remainder = nInterior % nprocs;

    for (int r = 0; r < nprocs; ++r)
    {
        int rnloc = base + (r < remainder);

        int start = r * base + (r < remainder ? r : remainder);

        double *ra, *rb, *rc, *rl, *ru, *rS;

        if (r == 0)
        {
            ra = (double *)a;
            rb = (double *)b;
            rc = (double *)c;
            rl = (double *)l;
            ru = (double *)u;
            rS = (double *)S;
        }
        else
        {
            ra = malloc(rnloc * sizeof(double));
            rb = malloc(rnloc * sizeof(double));
            rc = malloc(rnloc * sizeof(double));

            rl = malloc(2 * rnloc * sizeof(double));
            ru = malloc(2 * rnloc * sizeof(double));
            rS = malloc(4 * sizeof(double));

            irecv(r, ra, rnloc * sizeof(double), 400);
            irecv(r, rb, rnloc * sizeof(double), 401);
            irecv(r, rc, rnloc * sizeof(double), 402);

            irecv(r, rl, 2 * rnloc * sizeof(double), 403);
            irecv(r, ru, 2 * rnloc * sizeof(double), 404);
            irecv(r, rS, 4 * sizeof(double), 405);

            msgwait();
        }

        // ========================================================
        // INSERT INTERIOR BLOCK A
        // ========================================================
        for (int i = 0; i < rnloc; ++i)
        {
            int gi = start + i;

            Aij(global_a, N, gi, gi) = ra[i];

            if (i < rnloc - 1)
                Aij(global_a, N, gi, gi + 1) = rb[i];

            if (i > 0)
                Aij(global_a, N, gi, gi - 1) = rc[i];
        }

        // ========================================================
        // INSERT COUPLING BLOCKS L AND U
        // ========================================================
        int left_sep = nInterior + r - 1;
        int right_sep = nInterior + r;

        for (int i = 0; i < rnloc; ++i)
        {
            int gi = start + i;

            if (r > 0)
            {
                // L: separator row, interior column
                Aij(global_a, N, left_sep, gi) =
                    Aij(rl, 2, 0, i);

                // U: interior row, separator column
                Aij(global_a, N, gi, left_sep) =
                    Aij(ru, rnloc, i, 0);
            }

            if (r < nprocs - 1)
            {
                Aij(global_a, N, right_sep, gi) =
                    Aij(rl, 2, 1, i);

                Aij(global_a, N, gi, right_sep) =
                    Aij(ru, rnloc, i, 1);
            }
        }

        // ========================================================
        // INSERT LOCAL SCHUR BLOCK S
        // ========================================================
        // Multiple ranks contribute to the same separator entry,
        // so contributions must be added, not overwritten.

        int sep[2] = {left_sep, right_sep};

        for (int i = 0; i < 2; ++i)
        {
            for (int j = 0; j < 2; ++j)
            {
                if (sep[i] >= 0 && sep[i] < N &&
                    sep[j] >= 0 && sep[j] < N &&
                    (i == 0 ? r > 0 : r < nprocs - 1) &&
                    (j == 0 ? r > 0 : r < nprocs - 1))
                {
                    Aij(global_a, N, sep[i], sep[j]) +=
                        Aij(rS, 2, i, j);
                }
            }
        }

        if (r != 0)
        {
            free(ra);
            free(rb);
            free(rc);
            free(rl);
            free(ru);
            free(rS);
        }
    }

    return global_a;
}

static void outmat(const double *a, int lda, int m, int n,
                   const char *name)
{
    char filename[128];
    snprintf(filename, sizeof(filename), "%s.txt", name);

    FILE *fp = fopen(filename, "w");

    if (!fp)
    {
        perror(filename);
        exit(EXIT_FAILURE);
    }

    printf("Writing matrix %s (%d x %d) to %s\n",
           name, m, n, filename);

    for (int i = 0; i < m; ++i)
    {
        for (int j = 0; j < n; ++j)
        {
            fprintf(fp, " %18.9e", Aij(a, lda, i, j));
        }
        fprintf(fp, "\n");
    }

    fclose(fp);
}

static void gather_solution(double *T, double *us, Simulation *data, double L)
{
    int rank = data->rank;
    int P = data->nprocs;
    int N = data->n;
    int tag = 100;

    if (rank == 0)
    {
        // Complete global temperature array
        double *Tglobal = malloc(N * sizeof(*Tglobal));
        int *owners = malloc(N * sizeof(*owners));

        // Copy rank 0 interior values
        for (int i = 0; i < data->nloc; ++i)
        {
            int gi = data->start + i;
            Tglobal[gi] = T[i];
            owners[gi] = 0;
        }

        // Receive interior values from all other ranks
        int nInterior = N - (P - 1);
        int base = nInterior / P;
        int remainder = nInterior % P;

        for (int p = 1; p < P; ++p)
        {
            int nloc = base + (p < remainder);
            int start = p * base + (p < remainder ? p : remainder) + p;

            irecv(p, &Tglobal[start], nloc * sizeof(double), tag);

            for (int i = 0; i < nloc; ++i)
            {
                owners[start + i] = p;
            }
        }

        // Complete all receives
        msgwait();

        // Insert separator values
        for (int p = 0; p < P - 1; ++p)
        {
            int nloc = base + (p < remainder);
            int start = p * base + (p < remainder ? p : remainder) + p;
            int sep_index = start + nloc;

            Tglobal[sep_index] = us[p];
            owners[sep_index] = p;
        }

        // Write output
        FILE *fp = fopen("Temperature.txt", "w");

        if (fp == NULL)
        {
            perror("Temperature.txt");
            free(Tglobal);
            free(owners);
            return;
        }

        fprintf(fp, "# x T I rank TExact Error\n");

        for (int i = 0; i < N; ++i)
        {
            double x = (i + 1) * data->dx;
            double exact = data->TL + (data->TR - data->TL) * x / L + (data->alpha * L * L / (M_PI * M_PI)) * sin(M_PI * x / L);

            fprintf(fp, "%.16e %.16e %d %d %.16e %.16e\n",
                    x, Tglobal[i], i, owners[i],
                    exact, fabs(Tglobal[i] - exact));
        }

        fclose(fp);
        free(Tglobal);
        free(owners);

        printf("Wrote complete solution to Temperature.txt\n");
    }
    else
    {
        // Send local interior temperatures to rank 0
        isend(0, T, data->nloc * sizeof(double), tag);
        msgwait();
    }
}

int main(int argc, char **argv)
{
    msg_init(&argc, &argv);
    // ============================================================
    // INPUTS
    // ============================================================

    double L = 15.0;
    int N = 16;
    double TL = 1.0;
    double TR = 1.0;
    double alpha = 1.0;

    // Read command-line arguments
    if (argc > 1)
        L = atof(argv[1]);
    if (argc > 2)
        N = atoi(argv[2]);
    if (argc > 3)
        TL = atof(argv[3]);
    if (argc > 4)
        TR = atof(argv[4]);
    if (argc > 5)
        alpha = atof(argv[5]);
    // ============================================================
    // PACK DATA
    // ============================================================
    Simulation data;
    // Parallel
    data.rank = msg_rank();
    data.nprocs = num_ranks() + 1;
    int nsep = data.nprocs - 1;
    // Global
    data.n = N;
    data.L = L;
    data.dx = L / (N + 1);
    data.TL = TL;
    data.TR = TR;
    data.alpha = alpha;
    // Local Data
    int nInterior = N - (data.nprocs - 1);
    int base = nInterior / data.nprocs;
    int remainder = nInterior % data.nprocs;
    int localN = base;
    if (data.rank < remainder)
    {
        localN += 1;
    }
    data.nloc = localN;
    data.start = data.rank * base + (data.rank < remainder ? data.rank : remainder) + data.rank;
    // Global ending index (inclusive)
    data.end = data.start + data.nloc - 1;
    printf("Hello World from rank %d!\n I have %d Nodes\nThis starts at %d and ends at %d\n", data.rank, data.nloc, data.start, data.end);
    // ============================================================
    // ALLOCATE MATRICES AND INITIALIZE
    // ============================================================
    double *a = malloc(data.nloc * sizeof(*a));
    double *b = malloc(data.nloc * sizeof(*b));
    double *c = malloc(data.nloc * sizeof(*c));

    double *l = malloc(data.nloc * 2 * sizeof(*l));
    double *u = malloc(2 * data.nloc * sizeof(*u));
    double *S = malloc(2 * 2 * sizeof(*S));

    double *f = malloc(data.nloc * sizeof(*f));
    double *fs = malloc(2 * sizeof(*fs));

    double *sa = malloc(nsep * sizeof(*sa));
    double *sb = malloc(nsep * sizeof(*sb));
    double *sc = malloc(nsep * sizeof(*sc));
    double *sf = malloc(nsep * sizeof(*sf));
    double *us = malloc(nsep * sizeof(*us));

    double *T = malloc(data.nloc * sizeof(*T));
    // Check allocation
    if (!a || !b || !c || !l || !u || !S || !f || !fs || !sa || !sb || !sc || !sf || !us || !T)
    {
        fprintf(stderr, "Memory allocation failed on rank %d\n", data.rank);
        free(a);
        free(b);
        free(c);
        free(l);
        free(u);
        free(S);
        free(f);
        free(fs);
        free(sa);
        free(sb);
        free(sc);
        free(sf);
        free(us);
        free(T);
        msg_finalize();
        return EXIT_FAILURE;
    }

    // Initialize
    init(a, b, c, l, u, S, f, fs, &data);
    double *global_a = gather_matrix(a, b, c, l, u, S, &data);

    local_elim(a, b, c, l, u, S, f, fs, &data);

    construct_schur(S, fs, sa, sb, sc, sf, &data);

    solve_schur(sa, sb, sc, sf, us, &data);
    // Separator boundary conditions on local problems
    double uleft = 0.0;
    double uright = 0.0;

    if (data.rank > 0)
        uleft = us[data.rank - 1];

    if (data.rank < data.nprocs - 1)
        uright = us[data.rank];

    for (int i = 0; i < data.nloc; ++i)
    {
        f[i] -= Aij(u, data.nloc, i, 0) * uleft;
        f[i] -= Aij(u, data.nloc, i, 1) * uright;
    }

    backsolve(a, b, f, T, data.nloc);

    gather_solution(T, us, &data, L);
    // ============================================================
    // OUTPUT
    // ============================================================
    for (int p = 0; p < data.nprocs; ++p)
    {
        if (data.rank == p)
        {
            printf("\n%6s %6s %12s %18s %18s %18s\n",
                   "Rank", "i", "x", "T Numerical", "T Exact", "Abs Error");

            for (int i = 0; i < data.nloc; ++i)
            {
                int gi = data.start + i;
                double x = (gi + 1) * data.dx;

                // Exact solution for sinusoidal forcing
                double T_exact = data.TL + (data.TR - data.TL) * x / data.L + (data.alpha * data.L * data.L / (M_PI * M_PI)) * sin(M_PI * x / data.L);

                printf("%6d %6d %12.6f %18.10e %18.10e %18.10e\n",
                       data.rank, gi, x, T[i], T_exact,
                       fabs(T[i] - T_exact));
            }

            fflush(stdout);
        }

        msg_barrier();
    }
    if (data.rank == 0)
    {
        outmat(global_a, data.n, data.n, data.n, "GlobalMatrix");

        free(global_a);
    }
    // ============================================================
    // FINALIZE
    // ============================================================

    free(a);
    free(b);
    free(c);
    free(l);
    free(u);
    free(S);
    free(f);
    free(fs);
    free(sa);
    free(sb);
    free(sc);
    free(sf);
    free(us);
    free(T);
    msg_finalize();
    return 0;
}
