/*
 * Usage:
 *   mpiexec -n P ./bench_poisson [Nx] [Ny] [nruns] [method]
 *
 * Examples:
 *   mpiexec -n 4 ./bench_poisson 512 512 20 dealer
 *   mpiexec -n 4 ./bench_poisson 512 512 20 crystal
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include "poisson.h"
#include "msg.h"

#ifndef M_PI
#define M_PI 3.141592653589793238462643383279502884
#endif


static double exact_u(double x, double y, double Lx, double Ly)
{
    return sin(M_PI*x/Lx)*sin(2.0*M_PI*y/Ly);
}

/* -Laplacian of the above */
static double rhs_f(double x, double y, double Lx, double Ly)
{
    const double c = M_PI*M_PI/(Lx*Lx) + 4.0*M_PI*M_PI/(Ly*Ly);
    return c*exact_u(x,y,Lx,Ly);
}


int main(int argc, char **argv)
{
    int Nx = 1024;
    int Ny = 1024;
    int nruns = 20;

    const int nwarmup = 3;

    const double Lx = 1.0;
    const double Ly = 1.0;

    poisson_plan p;

    double *F;
    double *U;

    int i, j, run;


    /* ------------------------------------------------------------
     * MPI initialization
     * ------------------------------------------------------------ */

    msg_init(&argc, &argv);

    const int rank = msg_rank();
    const int P    = num_ranks();


    /* ------------------------------------------------------------
     * Command-line arguments
     * ------------------------------------------------------------ */

    if (argc > 1)
        Nx = atoi(argv[1]);

    if (argc > 2)
        Ny = atoi(argv[2]);

    if (argc > 3)
        nruns = atoi(argv[3]);

    const char *method = "dealer";

    if (argc > 4)
        method = argv[4];
    /*
     * Number of interior unknowns.
     *
     * Nx and Ny correspond to nx+1 and ny+1 in the current solver.
     */
    const int nx = Nx - 1;
    const int ny = Ny - 1;


    /* ------------------------------------------------------------
     * Initialize Poisson solver
     * ------------------------------------------------------------ */

    if (poisson_plan_init(&p, nx, ny, Lx, Ly)) {
        if (rank == 0)
            fprintf(stderr, "poisson_plan_init failed\n");

        msg_finalize();
        return 1;
    }

    if (strcmp(method, "dealer") == 0) {

        p.transpose_method = TRANSPOSE_DEALER;

    }
    else if (strcmp(method, "crystal") == 0) {

        p.transpose_method = TRANSPOSE_CRYSTAL;

    }
    else {

        if (rank == 0)
            fprintf(stderr,
                    "Unknown transpose method '%s'. "
                    "Use 'dealer' or 'crystal'.\n",
                    method);

        poisson_plan_free(&p);
        msg_finalize();

        return 1;
    }
    const int local_nx   = p.local_nx;
    const int local_size = local_nx * ny;


    F = (double *)malloc((size_t)local_size * sizeof(double));
    U = (double *)malloc((size_t)local_size * sizeof(double));

    if (!F || !U) {
        fprintf(stderr,
                "rank %d: allocation failed\n",
                rank);

        free(F);
        free(U);
        poisson_plan_free(&p);
        msg_finalize();

        return 2;
    }


    /* ------------------------------------------------------------
     * Construct RHS on this rank's local x-slab
     * ------------------------------------------------------------ */

    for (j = 0; j < ny; ++j) {

        const double y =
            (double)(j + 1) * p.hy;

        for (i = 0; i < local_nx; ++i) {

            const int global_i =
                p.x_start + i;

            const double x =
                (double)(global_i + 1) * p.hx;

            F[i + j*local_nx] =
                rhs_f(x, y, Lx, Ly);
        }
    }


    /* ------------------------------------------------------------
     * Warm-up
     * ------------------------------------------------------------ */

    for (run = 0; run < nwarmup; ++run)
        poisson_solve(&p, F, U);


    /* ------------------------------------------------------------
     * Benchmark
     * ------------------------------------------------------------ */

    double total_sum     = 0.0;
    double fst_sum       = 0.0;
    double transpose_sum = 0.0;
    double divide_sum    = 0.0;
    double comm_sum      = 0.0;
    for (run = 0; run < nruns; ++run) {

        poisson_solve(&p, F, U);

        total_sum     += p.time_total;
        fst_sum       += p.time_fst;
        transpose_sum += p.time_transpose;
        divide_sum    += p.time_divide;
        comm_sum      += p.time_comm;
    }


    const double total_avg =
        total_sum / (double)nruns;

    const double fst_avg =
        fst_sum / (double)nruns;

    const double transpose_avg =
        transpose_sum / (double)nruns;

    const double divide_avg =
        divide_sum / (double)nruns;

    const double comm_avg =
        comm_sum / (double)nruns;
    /* ------------------------------------------------------------
     * Error
     * ------------------------------------------------------------ */

    double local_error  = 0.0;
    double global_error = 0.0;

    for (j = 0; j < ny; ++j) {

        const double y =
            (double)(j + 1) * p.hy;

        for (i = 0; i < local_nx; ++i) {

            const int global_i =
                p.x_start + i;

            const double x =
                (double)(global_i + 1) * p.hx;

            const double uex =
                exact_u(x, y, Lx, Ly);

            const double error =
                fabs(U[i + j*local_nx] - uex);

            if (error > local_error)
                local_error = error;
        }
    }

    gmax_double(&local_error, &global_error, 1);

    /* ------------------------------------------------------------
     * Performance
     * ------------------------------------------------------------ */

    const double flops =
        2.0 * 10.0
        * (double)nx
        * (double)ny
        * (log2((double)Nx)
           + log2((double)Ny));

    const double gflops =
        (flops / total_avg) / 1.0e9;

    const long long n =
        (long long)nx * (long long)ny;

    const double n_per_rank =
        (double)n / (double)P;


    /* ------------------------------------------------------------
     * Output
     * ------------------------------------------------------------ */

    if (rank == 0) {

        printf("# method Nx Ny P n n/P error total fst transpose comm divide GFLOPS\n");

        printf("%s %d %d %d %lld %.6e "
            "%.9e %.9e %.9e %.9e %.9e %.9e %.6f\n",
            method,
            Nx,
            Ny,
            P,
            n,
            n_per_rank,
            global_error,
            total_avg,
            fst_avg,
            transpose_avg,
            comm_avg,
            divide_avg,
            gflops
        );
    }


    /* ------------------------------------------------------------
     * Cleanup
     * ------------------------------------------------------------ */

    free(F);
    free(U);

    poisson_plan_free(&p);

    msg_finalize();

    return 0;
}