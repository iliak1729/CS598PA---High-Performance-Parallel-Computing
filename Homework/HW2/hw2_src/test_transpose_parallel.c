/*
 * test_transpose_parallel.c
 *
 * Test the distributed dealer transpose.
 *
 * Global matrix:
 *
 *      A is m x n
 *
 * with
 *
 *      A(i,j) = 100*j + i
 *
 * Initially each rank owns a slab of the m dimension:
 *
 *      local_m x n
 *
 * After transpose_parallel_dealer(), each rank owns:
 *
 *      local_n x m
 *
 * representing the corresponding slab of A^T.
 */

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include "msg.h"
#include "transpose.h"
#define PRINT_TRANSPOSE 1
static void print_local_matrix(const char *name,
                               int rows, int cols,
                               const double *A,
                               int rank, int nranks)
{
    int r, i, j;

    /*
     * Print one rank at a time so MPI output does not get
     * mixed together.
     */
    for (r=0; r<nranks; ++r) {

        msg_barrier();

        if (rank == r) {

            printf("\nRank %d: %s (%d x %d)\n",
                   rank, name, rows, cols);

            for (i=0; i<rows; ++i) {
                printf("    ");

                for (j=0; j<cols; ++j) {
                    printf("%7.0f ", A[i + j*rows]);
                }

                printf("\n");
            }

            fflush(stdout);
        }
    }

    msg_barrier();
}


static void decompose_1d(int n, int rank, int nranks,
                         int *local_n, int *start)
{
    int base = n / nranks;
    int rem  = n % nranks;

    if (rank < rem) {
        *local_n = base + 1;
        *start   = rank * (base + 1);
    }
    else {
        *local_n = base;
        *start   = rem * (base + 1)
                 + (rank - rem) * base;
    }
}


int main(int argc, char **argv)
{
    int i, j;

    msg_init(&argc, &argv);

    const int rank   = msg_rank();
    const int nranks = num_ranks();

    /*
     * Deliberately choose dimensions that are not necessarily
     * divisible by nranks.
     */
    const int m = 7;
    const int n = 5;

    int local_m, m_start;
    int local_n, n_start;

    decompose_1d(m, rank, nranks,
                 &local_m, &m_start);

    decompose_1d(n, rank, nranks,
                 &local_n, &n_start);


    /*
     * Local input:
     *
     *      local_m x n
     */
    double *A = malloc((size_t)local_m * n * sizeof(double));

    /*
     * Local transposed output:
     *
     *      local_n x m
     */
    double *B = malloc((size_t)local_n * m * sizeof(double));

    if (!A || !B) {
        fprintf(stderr, "Rank %d: allocation failed\n", rank);
        free(A);
        free(B);
        msg_finalize();
        return 1;
    }


    /*
     * Fill our local portion of the global matrix.
     *
     * Global:
     *
     *      A(i,j) = 100*j + i
     *
     * Local storage:
     *
     *      A[local_i + j*local_m]
     */
    for (j = 0; j < n; ++j) {
        for (i = 0; i < local_m; ++i) {

            int global_i = m_start + i;

            A[i + j*local_m] =
                100.0*j + global_i;
        }
    }

#if PRINT_TRANSPOSE
    print_local_matrix("A before transpose",
                   local_m, n, A,
                   rank, nranks);
#endif
    /*
     * Perform distributed transpose.
     */
    transpose_parallel_dealer(
        m, n,
        local_m, local_n,
        A, B
    );

#if PRINT_TRANSPOSE
    print_local_matrix("B after transpose",
                   local_n, m, B,
                   rank, nranks);
#endif
    /*
     * Check result.
     *
     * B represents the local portion of A^T.
     *
     * Local j corresponds to:
     *
     *      global_j = n_start + j
     *
     * Therefore:
     *
     *      B(j,i) = A(i,global_j)
     *             = 100*global_j + i
     */
    int local_errors = 0;

    for (i = 0; i < m; ++i) {
        for (j = 0; j < local_n; ++j) {

            int global_j = n_start + j;

            double expected =
                100.0*global_j + i;

            double actual =
                B[j + i*local_n];

            if (fabs(actual - expected) > 1.0e-12) {

                printf(
                    "Rank %d ERROR: "
                    "B(global_j=%d, global_i=%d) "
                    "= %.1f, expected %.1f\n",
                    rank,
                    global_j,
                    i,
                    actual,
                    expected
                );

                local_errors++;
            }
        }
    }


    /*
     * Sum errors over all ranks.
     */
    double local_err_d  = (double)local_errors;
    double global_err_d = 0.0;

    gsum_double(&local_err_d,
                &global_err_d,
                1);


    if (rank == 0) {

        printf("\n");
        printf("Parallel transpose test\n");
        printf("-----------------------\n");
        printf("Global matrix: %d x %d\n", m, n);
        printf("MPI ranks:     %d\n", nranks);

        if ((int)global_err_d == 0)
            printf("PASS: distributed transpose is correct.\n");
        else
            printf("FAIL: %d incorrect entries.\n",
                   (int)global_err_d);
    }


    free(A);
    free(B);

    msg_finalize();

    return 0;
}