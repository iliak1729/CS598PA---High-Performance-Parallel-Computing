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
                               double * restrict B,double *comm_time)
{
    const int rank   = msg_rank();
    const int nranks = num_ranks();

    int round;
    int i, j;
    *comm_time = 0.0;
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
        double tcomm = msg_wtime();

        irecv(src,
              recvbuf,
              recv_count * (int)sizeof(double),
              round);

        isend(dest,
              sendbuf,
              send_count * (int)sizeof(double),
              round);

        msgwait();
        *comm_time += msg_wtime() - tcomm;

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

void transpose_parallel_crystal(int m, int n,
                                int local_m, int local_n,
                                const double * restrict A,
                                double * restrict B,double *comm_time)
{
    const int rank   = msg_rank();
    const int nranks = num_ranks();

    int i, j, dest, dim;
    *comm_time = 0.0;
    /*
     * Crystal routing requires the number of ranks
     * to be a power of two.
     */
    if (nranks & (nranks - 1)) {
        if (rank == 0) {
            fprintf(stderr,
                    "transpose_parallel_crystal: "
                    "number of ranks must be a power of two\n");
        }
        return;
    }

    /*
     * Maximum possible dimensions of one block.
     *
     * We pad every packet to the same size so that
     * packets can be routed without variable-length records.
     */
    const int max_local_m =
        (m + nranks - 1) / nranks;

    const int max_local_n =
        (n + nranks - 1) / nranks;

    /*
     * Payload contains the actual matrix data.
     */
    const size_t payload_size =
        (size_t)max_local_m * max_local_n;

    /*
     * Each record contains:
     *
     *   record[0] = destination rank
     *   record[1] = source rank
     *   record[2...] = matrix data
     *
     * dest and src are stored as doubles so the entire
     * record can remain one contiguous double buffer.
     */
    const size_t record_size =
        payload_size + 2;

    /*
     * Each rank always owns nranks records during routing.
     */
    double *cur =
        (double *)calloc(
            (size_t)nranks * record_size,
            sizeof(double));

    double *next =
        (double *)calloc(
            (size_t)nranks * record_size,
            sizeof(double));

    /*
     * At each crystal dimension, half of the records
     * are sent to the partner rank.
     */
    double *sendbuf =
        (double *)calloc(
            (size_t)(nranks / 2) * record_size,
            sizeof(double));

    double *recvbuf =
        (double *)calloc(
            (size_t)(nranks / 2) * record_size,
            sizeof(double));

    if (!cur || !next || !sendbuf || !recvbuf) {
        free(cur);
        free(next);
        free(sendbuf);
        free(recvbuf);
        return;
    }


    /* ============================================================
     * 1. INITIAL PACK
     *
     * Construct one record for every destination rank.
     * ============================================================ */

    for (dest = 0; dest < nranks; ++dest) {

        int dest_local_n;
        int dest_n_start;

        decompose_1d(n, dest, nranks,
                     &dest_local_n,
                     &dest_n_start);

        /*
         * Beginning of this destination's record.
         */
        double *record =
            &cur[(size_t)dest * record_size];

        /*
         * Store routing information.
         */
        record[0] = (double)dest;
        record[1] = (double)rank;

        /*
         * Payload begins after dest and src.
         */
        double *payload = &record[2];

        int pos = 0;

        /*
         * Pack the portion of A needed by this destination.
         */
        for (j = 0; j < dest_local_n; ++j) {

            const int global_j =
                dest_n_start + j;

            for (i = 0; i < local_m; ++i) {

                payload[pos++] =
                    A[i + global_j*local_m];
            }
        }

        /*
         * The remainder of the payload is already zero
         * because cur was allocated using calloc().
         */
    }


    /* ============================================================
     * 2. CRYSTAL ROUTING
     * ============================================================ */

    for (dim = 0; (1 << dim) < nranks; ++dim) {

        /*
         * Neighbor differing from us in bit dim.
         */
        const int partner =
            rank ^ (1 << dim);

        const int rank_bit =
            (rank >> dim) & 1;

        int nkeep = 0;
        int nsend = 0;

        /*
         * Examine every record currently held by this rank.
         */
        for (i = 0; i < nranks; ++i) {

            double *record =
                &cur[(size_t)i * record_size];

            /*
             * Destination now comes directly from the record.
             */
            const int packet_dest =
                (int)record[0];

            const int dest_bit =
                (packet_dest >> dim) & 1;

            /*
             * If this destination bit matches our rank bit,
             * the record stays here for this dimension.
             */
            if (dest_bit == rank_bit) {

                memcpy(
                    &next[(size_t)nkeep * record_size],
                    record,
                    record_size * sizeof(double));

                ++nkeep;
            }

            /*
             * Otherwise send it to our crystal partner.
             */
            else {

                memcpy(
                    &sendbuf[(size_t)nsend * record_size],
                    record,
                    record_size * sizeof(double));

                ++nsend;
            }
        }


        /*
         * Exchange outgoing records with our partner.
         *
         * For a power-of-two number of ranks, the partner
         * sends the same number of records back.
         */
        const size_t exchange_count =
            (size_t)nsend * record_size;
        double tcomm = msg_wtime();
        irecv(partner,
              recvbuf,
              (int)(exchange_count * sizeof(double)),
              dim);

        isend(partner,
              sendbuf,
              (int)(exchange_count * sizeof(double)),
              dim);

        msgwait();

        *comm_time += msg_wtime() - tcomm;
        /*
         * Append the records received from the partner
         * after the records that stayed here.
         */
        memcpy(
            &next[(size_t)nkeep * record_size],
            recvbuf,
            exchange_count * sizeof(double));


        /*
         * next is now the input for the next crystal dimension.
         */
        double *tmp = cur;
        cur  = next;
        next = tmp;
    }


    /* ============================================================
     * 3. FINAL UNPACK
     *
     * After all log2(P) dimensions, every record currently
     * on this rank should have:
     *
     *      destination == rank
     *
     * There should be exactly one record from every source.
     * ============================================================ */

    for (i = 0; i < nranks; ++i) {

        double *record =
            &cur[(size_t)i * record_size];

        const int packet_dest =
            (int)record[0];

        const int src =
            (int)record[1];

        /*
         * This should always be true if routing worked.
         */
        if (packet_dest != rank) {
            fprintf(stderr,
                    "rank %d: crystal routing error: "
                    "received packet for destination %d\n",
                    rank, packet_dest);

            continue;
        }

        /*
         * Determine how many global m indices this source owned.
         */
        int src_local_m;
        int src_m_start;

        decompose_1d(m, src, nranks,
                     &src_local_m,
                     &src_m_start);

        double *payload = &record[2];

        int pos = 0;

        /*
         * Unpack this source's contribution into the
         * locally owned portion of B.
         */
        for (j = 0; j < local_n; ++j) {

            for (int ii = 0; ii < src_local_m; ++ii) {

                const int global_i =
                    src_m_start + ii;

                B[j + global_i*local_n] =
                    payload[pos++];
            }
        }
    }


    /* ============================================================
     * Cleanup
     * ============================================================ */

    free(cur);
    free(next);
    free(sendbuf);
    free(recvbuf);
}

void transpose_real(int m, int n, const double * restrict A,
                                  double * restrict B)
{
    transpose_blocked(m,n,A,B);
}

