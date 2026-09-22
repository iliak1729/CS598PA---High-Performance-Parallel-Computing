#include "transpose.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "msg.h"

/* Unit-stride READ of A, strided WRITE of B. */
void transpose_naive(int m, int n, const double * restrict A,
                                   double * restrict B)
{
    int i,j;
    for (j=0; j<n; ++j)
        for (i=0; i<m; ++i)
            B[j + i*n] = A[i + j*m];
}

/* Tiled: both streams move in short unit-stride runs. */
void transpose_blocked(int m, int n, const double * restrict A,
                                     double * restrict B)
{
    const int TS = TRANSPOSE_TS;
    int ii,jj,i,j;

    for (jj=0; jj<n; jj+=TS) {
        const int jmax = (jj+TS < n) ? jj+TS : n;
        for (ii=0; ii<m; ii+=TS) {
            const int imax = (ii+TS < m) ? ii+TS : m;
            for (j=jj; j<jmax; ++j)
                for (i=ii; i<imax; ++i)
                    B[j + i*n] = A[i + j*m];
        }
    }
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


void transpose_parallel_dealer(int m, int n,
                               int local_m, int local_n,
                               const double * restrict A,
                               double * restrict B)
{
    const int rank   = msg_rank();
    const int nranks = num_ranks();

    int round;
    int i, j;
    printf("rank %d: transpose_parallel_dealer(m=%d, n=%d, local_m=%d, local_n=%d)\n",
           rank, m, n, local_m, local_n);
    /*
     * Largest possible message in either direction.
     *
     * A message contains:
     *
     *     local source m extent
     *          x
     *     local destination n extent
     *
     * doubles.
     */
    int max_local_m = (m + nranks - 1) / nranks;
    int max_local_n = (n + nranks - 1) / nranks;

    size_t max_count = (size_t)max_local_m * max_local_n;

    double *sendbuf =
        (double *)malloc(max_count * sizeof(double));

    double *recvbuf =
        (double *)malloc(max_count * sizeof(double));

    if (!sendbuf || !recvbuf) {
        free(sendbuf);
        free(recvbuf);
        return;
    }


    /*
     * Dealer schedule.
     *
     * At round k:
     *
     *     send to   (rank + k) % nranks
     *     recv from (rank - k + nranks) % nranks
     *
     * After nranks rounds, every rank has communicated directly
     * with every other rank.
     */
    for (round = 0; round < nranks; ++round) {

        const int dest =
            (rank + round) % nranks;

        const int src =
            (rank - round + nranks) % nranks;


        /*
         * Determine the n-range owned by our destination.
         */
        int dest_local_n;
        int dest_n_start;

        decompose_1d(n, dest, nranks,
                     &dest_local_n,
                     &dest_n_start);


        /*
         * Determine the m-range owned by our source.
         */
        int src_local_m;
        int src_m_start;

        decompose_1d(m, src, nranks,
                     &src_local_m,
                     &src_m_start);


        /*
         * --------------------------------------------------------
         * PACK
         * --------------------------------------------------------
         *
         * Our local input matrix is:
         *
         *     local_m x n
         *
         * A(local_i, global_j) is stored as:
         *
         *     A[local_i + global_j*local_m]
         *
         * Destination "dest" only needs its portion of the
         * global n dimension.
         */
        int pos = 0;

        for (j = 0; j < dest_local_n; ++j) {

            int global_j = dest_n_start + j;

            for (i = 0; i < local_m; ++i) {

                sendbuf[pos++] =
                    A[i + global_j*local_m];
            }
        }


        /*
         * Number of doubles sent and received this round.
         */
        const int send_count =
            local_m * dest_local_n;

        const int recv_count =
            src_local_m * local_n;


        /*
         * --------------------------------------------------------
         * COMMUNICATION
         * --------------------------------------------------------
         */
        irecv(src,
              recvbuf,
              recv_count * (int)sizeof(double),
              round);

        isend(dest,
              sendbuf,
              send_count * (int)sizeof(double),
              round);

        msgwait();


        /*
         * --------------------------------------------------------
         * UNPACK + TRANSPOSE
         * --------------------------------------------------------
         *
         * The output matrix on this rank is:
         *
         *     local_n x m
         *
         * B(local_j, global_i) is:
         *
         *     B[local_j + global_i*local_n]
         *
         * The received data came from source rank "src",
         * whose global m range starts at src_m_start.
         */
        pos = 0;

        for (j = 0; j < local_n; ++j) {

            for (i = 0; i < src_local_m; ++i) {

                int global_i = src_m_start + i;

                B[j + global_i*local_n] =
                    recvbuf[pos++];
            }
        }
    }


    free(sendbuf);
    free(recvbuf);
}

void transpose_real(int m, int n, const double * restrict A,
                                  double * restrict B)
{
    transpose_blocked(m,n,A,B);
}

