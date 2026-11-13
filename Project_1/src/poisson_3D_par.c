#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stddef.h>
#include "poisson_3D_par.h"
#include "poisson_3D_comm.h"

#define PI 3.14159265358979323846

#define IDX(i, j, k) \
    (((size_t)(k) * (g->ny + 2) + (j)) * (g->nx + 2) + (i))

void setup_par_domains(Grid3D *g, int global_nx, int global_ny, int global_nz, const int pdims[3], const int pcoords[3])
{
    int global_n[3] = {global_nx, global_ny, global_nz};

    int local_n[3];
    int start[3];

    for (int d = 0; d < 3; ++d) // Loop Over Dimensions
    {
        // Initial Guess and Remainder
        int base = global_n[d] / pdims[d];
        int remainder = global_n[d] % pdims[d];

        // Distribute Remaining cells among first few ranks
        local_n[d] = base + (pcoords[d] < remainder ? 1 : 0);

        // Starting Global Index
        start[d] = pcoords[d] * base + (pcoords[d] < remainder ? pcoords[d] : remainder);
    }

    // Local Interior
    g->nx = local_n[0];
    g->ny = local_n[1];
    g->nz = local_n[2];

    // Global interior dimensions
    g->global_nx = global_nx;
    g->global_ny = global_ny;
    g->global_nz = global_nz;

    // Global starting indices
    g->start_x = start[0];
    g->start_y = start[1];
    g->start_z = start[2];

    // Physical grid spacing
    g->dx = 1.0 / (global_nx + 1);
    g->dy = 1.0 / (global_ny + 1);
    g->dz = 1.0 / (global_nz + 1);
}
// This dot product only uses interior unknowns instead of all values
double grid_dot_product(
    const double *x,
    const double *y,
    const Grid3D *g)
{
    double local_sum = 0.0;

    for (int k = 1; k <= g->nz; ++k)
        for (int j = 1; j <= g->ny; ++j)
            for (int i = 1; i <= g->nx; ++i)
            {
                size_t l = IDX(i, j, k);
                local_sum += x[l] * y[l];
            }

    return comm_sum(local_sum);
}

// Enacts A on p to get w
void ax(
    double *w,
    double *p,
    const Grid3D *g)
{
    const double dxi = 1.0 / (g->dx * g->dx);
    const double dyi = 1.0 / (g->dy * g->dy);
    const double dzi = 1.0 / (g->dz * g->dz);

    const double diag = 2.0 * (dxi + dyi + dzi);

    /* Refresh neighboring values before stencil evaluation. */
    update_boudnary(p, g->nx, g->ny, g->nz);

    for (int k = 1; k <= g->nz; ++k)
    {
        for (int j = 1; j <= g->ny; ++j)
        {
            for (int i = 1; i <= g->nx; ++i)
            {
                int l = IDX(i, j, k);

                w[l] = diag * p[l] - dxi * (p[IDX(i - 1, j, k)] + p[IDX(i + 1, j, k)]) - dyi * (p[IDX(i, j - 1, k)] + p[IDX(i, j + 1, k)]) - dzi * (p[IDX(i, j, k - 1)] + p[IDX(i, j, k + 1)]);
            }
        }
    }
}
// x = y+a*x
void add2s1(
    double *x,
    const double *y,
    double a,
    const Grid3D *g)
{
    for (int k = 1; k <= g->nz; ++k)
        for (int j = 1; j <= g->ny; ++j)
            for (int i = 1; i <= g->nx; ++i)
            {
                size_t l = IDX(i, j, k);
                x[l] = y[l] + a * x[l];
            }
}
// x = x + a*y
void add2s2(
    double *x,
    const double *y,
    double a,
    const Grid3D *g)
{
    for (int k = 1; k <= g->nz; ++k)
        for (int j = 1; j <= g->ny; ++j)
            for (int i = 1; i <= g->nx; ++i)
            {
                size_t l = IDX(i, j, k);
                x[l] += a * y[l];
            }
}

// Diagonal Preconditioning
void apply_preconditioner(
    double *z,
    const double *r,
    const Grid3D *g)
{
    double dxi = 1.0 / (g->dx * g->dx);
    double dyi = 1.0 / (g->dy * g->dy);
    double dzi = 1.0 / (g->dz * g->dz);

    double dinv = 1.0 / (2.0 * (dxi + dyi + dzi));

    for (int k = 1; k <= g->nz; ++k)
        for (int j = 1; j <= g->ny; ++j)
            for (int i = 1; i <= g->nx; ++i)
            {
                size_t l = IDX(i, j, k);
                z[l] = dinv * r[l];
            }
}

int jpcg_solve(
    double *x,
    const double *b,
    const Grid3D *g,
    int maxit,
    double *tol,
    int rank)
{
    int n = (g->nx + 2) * (g->ny + 2) * (g->nz + 2);

    double *r = calloc(n, sizeof(double));
    double *p = calloc(n, sizeof(double));
    double *w = calloc(n, sizeof(double));
    double *z = calloc(n, sizeof(double));

    if (!r || !p || !w || !z)
    {
        fprintf(stderr, "Rank %d: allocation failed\n", rank);
        free(r);
        free(p);
        free(w);
        free(z);
        return -1;
    }

    // Initial residual: r = b - A*x
    ax(w, x, g);

    for (int k = 1; k <= g->nz; ++k)
        for (int j = 1; j <= g->ny; ++j)
            for (int i = 1; i <= g->nx; ++i)
            {
                size_t l = IDX(i, j, k);
                r[l] = b[l] - w[l];
            }

    double r0 = sqrt(grid_dot_product(r, r, g));
    double rel = 0.0;
    int iterations = 0;

    if (r0 == 0.0)
    {
        *tol = 0.0;
        free(r);
        free(p);
        free(w);
        free(z);
        return iterations;
    }

    double rho_old = 0.0;

    for (int iter = 1; iter <= maxit; ++iter)
    {
        /* z = M^{-1} r */
        apply_preconditioner(z, r, g);

        double rho = grid_dot_product(r, z, g);

        if (rho <= 0.0 || !isfinite(rho))
        {
            iterations = -1;
            break;
        }

        if (iter == 1)
        {
            /* p = z */
            add2s1(p, z, 0.0, g);
        }
        else
        {
            double beta = rho / rho_old;

            /* p = z + beta*p */
            add2s1(p, z, beta, g);
        }

        /* w = A*p, including halo exchange */
        ax(w, p, g);

        double gamma = grid_dot_product(p, w, g);

        if (gamma <= 0.0 || !isfinite(gamma))
        {
            iterations = -1;
            break;
        }

        double alpha = rho / gamma;

        /* x = x + alpha*p */
        add2s2(x, p, alpha, g);

        /* r = r - alpha*w */
        add2s2(r, w, -alpha, g);

        rel = sqrt(grid_dot_product(r, r, g)) / r0;

        iterations = iter;

        if (rank == 0 && (iter == 1 || iter % 50 == 0))
        {
            printf("Iteration %5d  Relative residual: %.9e\n",
                   iter, rel);
        }

        if (rel <= *tol)
            break;

        rho_old = rho;
    }

    *tol = rel;

    // Cleanup
    free(r);
    free(p);
    free(w);
    free(z);

    return iterations;
}

/* ---------------------------------------------------------
 * Manufactured solution:
 *     u = sin(pi*x) sin(pi*y) sin(pi*z)
 *     f = 3*pi^2*u
 * --------------------------------------------------------- */
double exact_solution(double x, double y, double z)
{
    return sin(PI * x) * sin(PI * y) * sin(PI * z);
}

void setup_rhs(double *b, const Grid3D *g)
{
    for (int k = 1; k <= g->nz; ++k)
        for (int j = 1; j <= g->ny; ++j)
            for (int i = 1; i <= g->nx; ++i)
            {
                double x = (g->start_x + i) * g->dx;
                double y = (g->start_y + j) * g->dy;
                double z = (g->start_z + k) * g->dz;

                b[IDX(i, j, k)] = 1.0;
                // 3.0 * PI * PI * exact_solution(x, y, z);
            }
}

double compute_error(
    const double *u,
    const Grid3D *g)
{
    double local_error = 0.0;

    for (int k = 1; k <= g->nz; ++k)
        for (int j = 1; j <= g->ny; ++j)
            for (int i = 1; i <= g->nx; ++i)
            {
                double x = (g->start_x + i) * g->dx;
                double y = (g->start_y + j) * g->dy;
                double z = (g->start_z + k) * g->dz;

                double diff = u[IDX(i, j, k)] - exact_solution(x, y, z);

                local_error += diff * diff;
            }

    double global_error = comm_sum(local_error);

    double n_global = (double)g->global_nx * g->global_ny * g->global_nz;

    return sqrt(global_error / n_global);
}

int main(int argc, char **argv)
{
    int rank, size;
    int pdims[3], pcoords[3];

    // Default global grid dimensions
    int global_nx = 64;
    int global_ny = 64;
    int global_nz = 64;

    // Default processor decomposition
    int px = 1;
    int py = 1;
    int pz = 1;

    if (argc == 7)
    {
        global_nx = atoi(argv[1]);
        global_ny = atoi(argv[2]);
        global_nz = atoi(argv[3]);

        px = atoi(argv[4]);
        py = atoi(argv[5]);
        pz = atoi(argv[6]);
    }
    else if (argc != 1)
    {
        fprintf(stderr,
                "Usage: %s [Nx Ny Nz Px Py Pz]\n",
                argv[0]);
        return EXIT_FAILURE;
    }

    // Initialize MPI with requested decomposition
    comm_setup(
        &rank, &size,
        pdims, pcoords,
        px, py, pz);

    // Validate global grid dimensions
    if (global_nx <= 0 ||
        global_ny <= 0 ||
        global_nz <= 0 ||
        global_nx < px ||
        global_ny < py ||
        global_nz < pz)
    {
        if (rank == 0)
        {
            fprintf(stderr,
                    "Invalid global grid dimensions.\n");
        }

        comm_finalize();
        return EXIT_FAILURE;
    }

    Grid3D grid;

    setup_par_domains(
        &grid,
        global_nx, global_ny, global_nz,
        pdims, pcoords);

    // Local dimensions
    int nx = grid.nx;
    int ny = grid.ny;
    int nz = grid.nz;

    // Allocate local arrays including ghost layers
    size_t n = (size_t)(nx + 2) * (ny + 2) * (nz + 2);

    double *u = calloc(n, sizeof(double));
    double *f = calloc(n, sizeof(double));

    // Keep the rest of your existing main() unchanged

    if (!u || !f)
    {
        fprintf(stderr, "Rank %d: allocation failed\n", rank);
        free(u);
        free(f);
        comm_finalize();
        return EXIT_FAILURE;
    }

    setup_rhs(f, &grid);

    int maxit = 5000;
    double tol = 1.0e-8;

    comm_sync();
    double t0 = comm_wtime();

    int iterations = jpcg_solve(
        u, f, &grid, maxit, &tol, rank);

    comm_sync();
    double elapsed = comm_wtime() - t0;
    elapsed = comm_max(elapsed);

    double error = compute_error(u, &grid);

    if (rank == 0)
    {
        printf("\n====================================\n");
        printf("3D Jacobi-PCG Poisson Solver\n");
        printf("====================================\n");
        printf("MPI ranks:         %d\n", size);
        printf("Global grid:       %d x %d x %d\n",
               grid.global_nx, grid.global_ny, grid.global_nz);
        printf("Local grid:        %d x %d x %d\n",
               nx, ny, nz);
        printf("Iterations:        %d\n", iterations);
        printf("Relative residual: %.9e\n", tol);
        printf("RMS error:         %.9e\n", error);
        printf("Solve time:        %.9e s\n", elapsed);
        printf("====================================\n");
    }

    free(u);
    free(f);

    comm_finalize();

    return iterations < 0 ? EXIT_FAILURE : EXIT_SUCCESS;
}

#undef IDX
