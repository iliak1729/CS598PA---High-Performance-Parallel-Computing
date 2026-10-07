#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "poisson.h"
#include "transpose.h"
#include "msg.h"
#ifndef M_PI
#define M_PI 3.141592653589793238462643383279502884
#endif

static void decompose_1d(int n, int rank, int nranks, 
                         int *local_n,int *start) 
{
    int base = n / nranks;
    int rem  = n % nranks;

    if (rank < rem) {
        *local_n = base + 1;
        *start   = rank * (base + 1);
    } else {
        *local_n = base;
        *start   = rem * (base + 1) + (rank - rem) * base;
    }
}

int poisson_plan_init(poisson_plan *p,
                           int nx, int ny, double Lx, double Ly)
{
    int i,j;

    p->nx=nx; p->ny=ny; p->Lx=Lx; p->Ly=Ly;
    p->hx = Lx/(double)(nx+1);
    p->hy = Ly/(double)(ny+1);
    p->rank   = msg_rank();
    p->nranks = num_ranks();

    decompose_1d(nx, p->rank, p->nranks,
                &p->local_nx, &p->x_start);

    decompose_1d(ny, p->rank, p->nranks,
                &p->local_ny, &p->y_start);
    p->lamx=0; p->lamy=0; p->A=0; p->B=0;
    p->transpose_method = TRANSPOSE_DEALER; /*Default*/

    /* Allocate local matrices. */
    /* fy contracts along y: the matrix is local nx x ny, batch = nx. */
    if (block_fst_plan_init(&p->fy,p->local_nx,ny)) return 1;
    /* fx contracts along x: the matrix is local ny x nx, batch = ny. */
    if (block_fst_plan_init(&p->fx,p->local_ny,nx)) { block_fst_plan_free(&p->fy); return 1; }

    p->lamx = (double*) malloc((size_t)nx*sizeof(double));
    p->lamy = (double*) malloc((size_t)ny*sizeof(double));

    /* Allocate local matrices. */
    p->A    = (double*) malloc((size_t)p->local_nx*ny*sizeof(double));
    p->B    = (double*) malloc((size_t)nx*p->local_ny*sizeof(double));
    if (!p->lamx || !p->lamy || !p->A || !p->B) {
        poisson_plan_free(p); return 2;
    }

    /* Exact eigenvalues of the 5-point operator. */
    for (i=0; i<nx; ++i) {
        double s = sin(0.5*M_PI*(double)(i+1)/(double)(nx+1));
        p->lamx[i] = 4.0*s*s/(p->hx*p->hx);
    }
    for (j=0; j<ny; ++j) {
        double s = sin(0.5*M_PI*(double)(j+1)/(double)(ny+1));
        p->lamy[j] = 4.0*s*s/(p->hy*p->hy);
    }
    return 0;
}

void poisson_plan_free(poisson_plan *p)
{
    block_fst_plan_free(&p->fx);
    block_fst_plan_free(&p->fy);
    free(p->lamx); p->lamx=0;
    free(p->lamy); p->lamy=0;
    free(p->A);    p->A=0;
    free(p->B);    p->B=0;
}

void poisson_solve(poisson_plan *p,
                        const double * restrict F, double * restrict U)
{
    const int nx=p->nx, ny=p->ny;
    const int local_nx=p->local_nx, local_ny=p->local_ny;
    double * restrict A = p->A;
    double * restrict B = p->B;
    int i,j,k;

    for (k=0; k<local_nx*ny; ++k) A[k]=F[k];

    double local_fst = 0.0;
    double local_transpose = 0.0;
    double local_divide = 0.0;
    double local_comm = 0.0;
    double comm_time;
    double t;
    /* ---- timed region: the actual FST solve, steps 1-7 -------------- */
    msg_barrier();
    const double t0 = msg_wtime();

    /* 1. transform along y: A is nx x ny, contract over the ny index */
    t = msg_wtime();
    block_fst_apply(&p->fy,A);
    local_fst += msg_wtime() - t;

    /* 2. A(1:nx,1:ny) -> B(1:ny,1:nx) */
    t = msg_wtime();
    if (p->transpose_method == TRANSPOSE_CRYSTAL) {
    transpose_parallel_crystal(nx, ny,
                               local_nx, local_ny,
                               A, B,&comm_time);
    }
    else {
        transpose_parallel_dealer(nx, ny,
                                local_nx, local_ny,
                                A, B,&comm_time);
    }
    local_transpose += msg_wtime() - t;
    local_comm += comm_time;
    /* 3. transform along x: B is ny x nx, contract over the nx index */
    t = msg_wtime();
    block_fst_apply(&p->fx,B);
    local_fst += msg_wtime() - t;
    /* 4. divide by the eigenvalues;  B(j,i) = B[j + i*ny] */
    t = msg_wtime();
    for (i=0; i<nx; ++i) {

        const double lx = p->lamx[i];

        double * restrict Bi =
            &B[i*local_ny];

        for (j=0; j<local_ny; ++j) {

            const int global_j =
                p->y_start + j;

            Bi[j] /=
                (lx + p->lamy[global_j]);
        }
    }
    local_divide += msg_wtime() - t;
    /* 5. back along x (S is its own inverse) */
    t = msg_wtime();
    block_fst_apply(&p->fx,B);
    local_fst += msg_wtime() - t;

    /* 6. B(1:ny,1:nx) -> A(1:nx,1:ny) */
    t = msg_wtime();
    if (p->transpose_method == TRANSPOSE_CRYSTAL) {
        transpose_parallel_crystal(ny, nx,
                                local_ny, local_nx,
                                B, A,&comm_time);
    }
    else {
        transpose_parallel_dealer(ny, nx,
                                local_ny, local_nx,
                                B, A,&comm_time);
    }
    local_transpose += msg_wtime() - t;
    local_comm += comm_time;
    /* 7. back along y */
    t = msg_wtime();
    block_fst_apply(&p->fy,A);
    local_fst += msg_wtime() - t;

    const double t1 = msg_wtime();
    /* ---- end timed region -------------------------------------------- */
    double local_total = t1-t0;

    /* Reduce the local elapsed time to the global elapsed time. */
    gmax_double(&local_total,&p->time_total,1);
    gmax_double(&local_fst,&p->time_fst,1);
    gmax_double(&local_transpose,&p->time_transpose,1);
    gmax_double(&local_divide,&p->time_divide,1);
    gmax_double(&local_comm,&p->time_comm,1);
    // if (msg_rank()==0) {
    //     const int    Nx      = nx+1, Ny = ny+1;
    //     /* 4 batched-FST passes (steps 1,3,5,7), each O(m n log2 n);
    //      * the crude count below folds all four into one estimate:
    //      * flops ~ 2*10*nx*ny*(log2(Nx)+log2(Ny)). */
    //     const double flops  = 2.0*10.0*(double)nx*(double)ny*
    //                            (log2((double)Nx) + log2((double)Ny));
    //     const double elapsed = p->time_total;
    //     const double gflops = (flops/elapsed)/1e9;
    //     printf("poisson_solve: Nx %8d  Ny %8d  elapsed %12.6f s  "
    //            "GFLOPS %8.3f\n", Nx, Ny, elapsed, gflops);
    // }

    for (k=0; k<local_nx*ny; ++k) U[k]=A[k];
}

/* F = -Laplacian_h U, zero Dirichlet data outside the index range. */
void poisson_residual_op(const poisson_plan *p,
                         const double * restrict U,
                         double * restrict F)
{
    const int ny       = p->ny;
    const int local_nx = p->local_nx;

    const int rank   = p->rank;
    const int nranks = p->nranks;

    const double cx = 1.0/(p->hx*p->hx);
    const double cy = 1.0/(p->hy*p->hy);

    int i,j;

    /*
     * Boundary values received from neighboring x-slabs.
     *
     * left[j]  = U value immediately west of this rank
     * right[j] = U value immediately east of this rank
     */
    double *left  = (double*)malloc((size_t)ny*sizeof(double));
    double *right = (double*)malloc((size_t)ny*sizeof(double));

    double *send_left  = (double*)malloc((size_t)ny*sizeof(double));
    double *send_right = (double*)malloc((size_t)ny*sizeof(double));

    if (!left || !right || !send_left || !send_right) {
        free(left);
        free(right);
        free(send_left);
        free(send_right);
        return;
    }


    /*
     * Extract this rank's first and last x-columns.
     *
     * U is stored as:
     *
     *     U[i + j*local_nx]
     */
    for (j=0; j<ny; ++j) {
        send_left[j]  = U[0 + j*local_nx];
        send_right[j] = U[(local_nx-1) + j*local_nx];

        /*
         * Default to the zero Dirichlet boundary condition.
         */
        left[j]  = 0.0;
        right[j] = 0.0;
    }


    /*
     * Exchange x-boundary data with neighboring ranks.
     */
    if (rank > 0) {
        irecv(rank-1, left,
              ny*(int)sizeof(double), 100);

        isend(rank-1, send_left,
              ny*(int)sizeof(double), 101);
    }

    if (rank < nranks-1) {
        irecv(rank+1, right,
              ny*(int)sizeof(double), 101);

        isend(rank+1, send_right,
              ny*(int)sizeof(double), 100);
    }

    msgwait();


    /*
     * Apply the local 5-point stencil.
     */
    for (j=0; j<ny; ++j) {

        for (i=0; i<local_nx; ++i) {

            const double c =
                U[i + j*local_nx];


            /*
             * West neighbor.
             */
            double w;

            if (i > 0)
                w = U[(i-1) + j*local_nx];
            else
                w = left[j];


            /*
             * East neighbor.
             */
            double e;

            if (i < local_nx-1)
                e = U[(i+1) + j*local_nx];
            else
                e = right[j];


            /*
             * South/north neighbors are always local because
             * each rank owns the complete y direction.
             */
            const double s =
                (j>0)
                ? U[i + (j-1)*local_nx]
                : 0.0;

            const double nn =
                (j<ny-1)
                ? U[i + (j+1)*local_nx]
                : 0.0;


            F[i + j*local_nx] =
                cx*(2.0*c - w - e)
              + cy*(2.0*c - s - nn);
        }
    }


    free(left);
    free(right);
    free(send_left);
    free(send_right);
}

