/* Block LU factorization test using CBLAS DGEMM, translated from factor.f.
 *
 * Storage is one-dimensional, column-major, so that
 *     A(i,j) <-> a[i + lda*j]       (0-based C indices)
 * This preserves the memory-access pattern of the Fortran code.
 *
 * For each diagonal block A:
 *     A -> L U
 *     C -> -C U^{-1}
 *     B ->  L^{-1} B
 *     D -> D + C B
 *
 * No pivoting is performed, matching factor.f.
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include "msg.h"
#include <Accelerate/Accelerate.h>

#define Aij(a,ld,i,j) ((a)[(size_t)(i) + (size_t)(ld)*(size_t)(j)])

static double cpu_time(void) // No Update Needed
{
    return (double)clock() / (double)CLOCKS_PER_SEC;
}
// Update randm to do local allocations properly.
static void randm(double *a, int lda, int m, int n,int mloc, int nloc, int p, int q, int P, int Q) 
{
    const double pi = 4.0*atan(1.0);

    for (int local_j = 0; local_j < nloc;++local_j){
        // Global column index
        int global_j = q + Q*local_j;
        // printf("global_j=%d\n", global_j);
        for(int local_i = 0; local_i < mloc; ++local_i) {
            // Global row Index
            int global_i = p + P*local_i;
            Aij(a,lda,local_i,local_j) = cos(pi*(double)(global_i+1)*(double)(global_j+1)/(double)m);
            // Diagonal shift
            if(global_i == global_j) {
                Aij(a,lda,local_i,local_j) += 5.0;
            }
        }

    }
}

/* C = C + A*B, all matrices stored column-major.
 * A is m x l with leading dimension lda.
 * B is l x n with leading dimension ldb.
 * C is m x n with leading dimension ldc.
 */
/* C = C + A*B using optimized CBLAS DGEMM from Apple Accelerate.
 * All matrices are column-major, matching the original Fortran storage.
 * A is m x l, B is l x n, C is m x n.
 */
static void mxma(const double *a, int lda, int m,
                 const double *b, int ldb, int l,
                 double *c, int ldc, int n)
{
    if (m<=0 || l<=0 || n<=0) return;

    cblas_dgemm(CblasColMajor, CblasNoTrans, CblasNoTrans,
                m, n, l,
                1.0, a, lda,
                     b, ldb,
                1.0, c, ldc);
}

static void outmat(const double *a, int lda, int m, int n,
                   const char *name, int ie)
{
    char filename[64];
    snprintf(filename,sizeof(filename),"%.6s%d",name,abs(ie)%10);

    FILE *fp = fopen(filename,"w");
    if (!fp) {
        perror(filename);
        exit(EXIT_FAILURE);
    }

    printf("\n%d matrix: %.6s %d %d\n",ie,name,m,n);
    const int nout = (n < 20) ? n : 20;
    for (int i=0; i<m; ++i) {
        for (int j=0; j<nout; ++j)
            fprintf(fp," %18.9e",Aij(a,lda,i,j));
        fputc('\n',fp);
    }
    putchar('\n');
    fclose(fp);
}

static double *gather_matrix(const double *a, int lda,
                             int m, int n,
                             int mloc, int nloc,
                             int P, int Q,
                             int p, int q,
                             int rank, int nprocs)
{
    double *global_a = NULL;

    if (rank == 0) {
        global_a = malloc((size_t)m * (size_t)n * sizeof(double));

        if (!global_a) {
            fprintf(stderr, "Global matrix allocation failed\n");
            exit(EXIT_FAILURE);
        }
    }

    // Send local matrix from every nonzero rank
    if (rank != 0) {

        isend(0, a,
              (int)((size_t)mloc * (size_t)nloc * sizeof(double)),
              400);

        msgwait();

        return NULL;
    }

    // Rank 0 reconstructs the global matrix
    for (int r = 0; r < nprocs; ++r) {

        const int rp = r / Q;
        const int rq = r % Q;

        const int rm = (m > rp) ? (m - 1 - rp) / P + 1 : 0;
        const int rn = (n > rq) ? (n - 1 - rq) / Q + 1 : 0;

        double *buffer = NULL;

        if (r == 0) {
            buffer = (double *)a;
        }
        else {
            buffer = malloc((size_t)(rm > 0 ? rm : 1) *
                            (size_t)(rn > 0 ? rn : 1) *
                            sizeof(double));

            if (!buffer) {
                fprintf(stderr, "Receive buffer allocation failed\n");
                exit(EXIT_FAILURE);
            }

            irecv(r, buffer,
                  (int)((size_t)rm * (size_t)rn * sizeof(double)),
                  400);

            msgwait();
        }

        const int local_lda = (r == 0) ? lda : (rm > 0 ? rm : 1);

        for (int local_j = 0; local_j < rn; ++local_j) {
            const int global_j = rq + Q * local_j;

            for (int local_i = 0; local_i < rm; ++local_i) {
                const int global_i = rp + P * local_i;

                Aij(global_a, m, global_i, global_j) =
                    Aij(buffer, local_lda, local_i, local_j);
            }
        }

        if (r != 0)
            free(buffer);
    }

    return global_a;
}

static int parallel_factor(double *a, int lda,
                           int m, int n,
                           int mloc, int nloc,
                           int P, int Q,
                           int p, int q)
{
    const int kmax = (m < n) ? m : n;

    // ============================================================
    // Workspace
    // ============================================================

    double *col = malloc((size_t)(mloc > 0 ? mloc : 1) * sizeof(*col));
    double *row = malloc((size_t)(nloc > 0 ? nloc : 1) * sizeof(*row));

    if (!col || !row) {
        fprintf(stderr, "Workspace allocation failed\n");
        free(col);
        free(row);
        return -1;
    }

    // ============================================================
    // Gaussian Elimination
    // ============================================================

    for (int k = 0; k < kmax; ++k) {

        // Determine and broadcast pivot
        int pk = k % P;
        int qk = k % Q;
        int root = pk * Q + qk;

        // ============================================================
        // Broadcast Pivot
        // ============================================================
        double pivot = 0.0;
        if(p == pk && q == qk) {
            int local_i = k / P;
            int local_j = k / Q;
            pivot = Aij(a, lda, local_i, local_j);
        }

        // Broadcast
        bcast(&pivot, sizeof(pivot), root);

        // Zero Pivot Check
        if (pivot == 0.0) {
            if(p == pk && q == qk) {
                fprintf(stderr, "Zero pivot at k=%d\n", k+1);
            }
            free(col); free(row);
            return k+1;
        }
        // ============================================================
        // Broadcast the Pivot Row
        // ============================================================
        // Gather pivot row
        if(p == pk) { // Processors that contain the pivot row
            int local_i = k / P;
            for(int local_j = 0; local_j < nloc; ++local_j) {
                int global_j = q + Q*local_j;

                if(global_j > k) {
                    row[local_j] = Aij(a, lda, local_i, local_j);
                } else {
                    row[local_j] = 0.0; // Not part of the pivot row
                }
            }
        }

        // Broadcast the pivot row down
        int sender = pk * Q + q;
        int nbytes = (int)((size_t)nloc * sizeof(double));
        int tag = 100;

        if (p == pk) { // If p = hat p, then send the pivo row to all P in column q.
            for(int dest_p = 0; dest_p < P;++dest_p) {
                if(dest_p != pk) {
                    int dest_rank = dest_p * Q + q;
                    isend(dest_rank, row, nbytes, tag);
                }
            }
        } else { // else recieve the pivot row.
            irecv(sender,row,nbytes,tag);
        }
        msgwait(); // Wait for all sends and recieves to complete.
        // ============================================================
        // Compute and Broadcast the Multiplier Column
        // ============================================================
        // Gather Multipliers
        if(q == qk) {
            int local_j = k / Q;
            for(int local_i = 0; local_i < mloc; ++local_i) {
                int global_i = p + P*local_i;

                if(global_i > k) {
                    col[local_i] = Aij(a,lda,local_i,local_j) / pivot;
                    Aij(a,lda,local_i,local_j) = col[local_i];
                } else {
                    col[local_i] = 0.0;
                }
            }
        }
        // Broadcast the multipliers across the row
        sender = p * Q + qk;
        nbytes = (int)((size_t)mloc * sizeof(double));
        tag = 200;

        if (q == qk) { // If p = hat p, then send the pivo row to all P in column q.
            for(int dest_q = 0; dest_q < Q;++dest_q) {
                if(dest_q != qk) {
                    int dest_rank = p * Q + dest_q;
                    isend(dest_rank, col, nbytes, tag);
                }
            }
        } else { // else recieve the pivot row.
            irecv(sender,col,nbytes,tag);
        }
        msgwait(); // Wait for all sends and recieves to complete.f p = hat p, then send the multipliers to all P in column q.
        
        // Update local matrix
        for(int local_i =0; local_i < mloc; ++local_i) {
            int global_i = p + P*local_i;
            for(int local_j = 0; local_j < nloc; ++local_j) {
                int global_j = q + Q*local_j;

                if(global_i > k && global_j > k) {
                    Aij(a,lda,local_i,local_j) -= col[local_i] * row[local_j];
                }
            }
        }

    }

    // ============================================================
    // Cleanup
    // ============================================================

    free(col);
    free(row);

    return 0;
}

int main(int argc, char **argv)
{
    // ============================================================
    // MPI Initialization
    // ============================================================
    msg_init(&argc,&argv);
    const int rank = msg_rank();
    const int nprocs = num_ranks()+1;

    // Default parameters
    int m = 1803;
    int n = 1804;
    int P = 2;
    int Q = 2;

    // Read command-line arguments
    if (argc > 1) m = atoi(argv[1]);
    if (argc > 2) n = atoi(argv[2]);
    if (argc > 3) P = atoi(argv[3]);
    if (argc > 4) Q = atoi(argv[4]);

    // Validate dimensions
    if (m <= 0 || n <= 0 || P <= 0 || Q <= 0) {
        if (rank == 0)
            fprintf(stderr, "Error: m, n, P, and Q must be positive.\n");

        msg_finalize();
        return EXIT_FAILURE;
    }

    if (P * Q != nprocs) {
        if (rank == 0) {
            fprintf(stderr,"Error: P*Q != nprocs (%d*%d != %d)\n",P,Q,nprocs);
        }
        msg_finalize();
        return EXIT_FAILURE;
    }

    const int p = rank / Q; // This is the initial row of the processor grid
    const int q = rank % Q; // This is the initial column of the processor grid


     printf("Rank %d: p=%d, q=%d\n", rank, p, q);

    // ============================================================
    // Matrix Allocation and Definition
    // ============================================================
    const int mloc = (m > p) ? (m - 1 - p)/P + 1 : 0;
    const int nloc = (n > q) ? (n - 1 - q)/Q + 1 : 0;

    // Leading dimension of local matrix
    const int lda = (mloc > 0) ? mloc : 1;

    // Allocate Local Matrix
    const size_t mnloc = (size_t)lda * (size_t)(nloc >0 ? nloc : 1);
    double *a = malloc(mnloc * sizeof(*a));
    if (!a) {
        fprintf(stderr,"Rank %d: unable to allocate %.3f MB\n", rank,
                (double)(mnloc*sizeof(*a))/(1024.0*1024.0));
        msg_finalize();
        return EXIT_FAILURE;
    }
    
    // Initialize Local Matrix
    randm(a, lda, m, n, mloc, nloc, p, q, P, Q);
    
    printf("Rank %d (p=%d,q=%d): mloc=%d, nloc=%d, lda=%d\n",
       rank, p, q, mloc, nloc, lda);

    // ============================================================
    // Factor the Matrix
    // ============================================================
    msg_barrier();
    double t0 = msg_wtime();
    const int ierr = parallel_factor(a, lda, m, n, mloc, nloc, P, Q, p, q);
    
    double local_time = msg_wtime() - t0;
    // ============================================================
    // Max Time
    // ============================================================
    double max_time = local_time;

    if (rank == 0) {

        double *times = malloc((size_t)nprocs * sizeof(double));

        if (!times) {
            fprintf(stderr, "Timing allocation failed\n");
            exit(EXIT_FAILURE);
        }

        times[0] = local_time;

        for (int r = 1; r < nprocs; ++r) {
            irecv(r, &times[r], sizeof(double), 300);
        }

        msgwait();

        for (int r = 1; r < nprocs; ++r) {
            if (times[r] > max_time)
                max_time = times[r];
        }

        free(times);

    }
    else {

        isend(0, &local_time, sizeof(double), 300);
        msgwait();

    }

    if (rank == 0) {

        const double r = (double)((m < n) ? m : n);

        const double flops =
            2.0 * (double)m * (double)n * r
            - ((double)m + (double)n) * r * r
            + (2.0 / 3.0) * r * r * r;

        const double gflops = flops / (max_time * 1.0e9);

        printf("Matrix dimensions: %d x %d\n", m, n);
        printf("Processor grid:    %d x %d\n", P, Q);
        printf("MPI processes:     %d\n", nprocs);
        printf("Factorization time: %.6f seconds\n", max_time);
        printf("Performance:        %.3f GFLOPS\n", gflops);
        // Machine-readable output
        printf("RESULT,%d,%d,%d,%d,%.9e,%.9e\n",
             m, n, P, Q, max_time, gflops);
    }
    // ============================================================
    // Gather and Output Matrix
    // ============================================================
    double *global_a = gather_matrix(a, lda, m, n,
                                 mloc, nloc,
                                 P, Q, p, q,
                                 rank, nprocs);

    if (rank == 0) {
        outmat(global_a, m, m, n, "LU", ierr);

        free(global_a);
    }
    // ============================================================
    // Finalize
    // ============================================================
    msg_finalize();
    return 0;
}
