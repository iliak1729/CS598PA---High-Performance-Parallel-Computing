#include <stdio.h>
#include <stdlib.h>
#include "msg.h"

/* Function implemented in ping_pong.c */
double ping_pong(void *buf, int nbytes, int p, int nloop);

int main(int argc, char **argv)
{
    int rank;
    int p;
    int M;

    int j;
    int nwds;
    int byte;
    int nloop;

    double msg_vol = 100000.0;
    double time;

    FILE *fp = NULL;

    msg_init(&argc, &argv);

    rank = msg_rank();

    /*
     * num_ranks() returns the maximum valid rank.
     */
    M = num_ranks();

    /*
     * Only rank 0 opens and writes the output file.
     */
    if (rank == 0) {
        fp = fopen("timing.log", "w");

        if (fp == NULL) {
            fprintf(stderr, "Failed to open timing.log\n");
            msg_finalize();
            return 1;
        }

        fprintf(fp, "%8s %12s %12s %12s %15s\n",
                "p", "nwds", "bytes", "nloop", "RTT (s)");
    }

    /*
     * Allocate a buffer large enough for all message sizes.
     */
    int max_nwds = 200000;
    double *buf = malloc(max_nwds * sizeof(double));

    if (buf == NULL) {
        fprintf(stderr, "Rank %d: Failed to allocate buffer\n", rank);

        if (rank == 0)
            fclose(fp);

        msg_finalize();
        return 1;
    }

    /*
     * Test rank 0 against every available rank.
     */
    for (p = 0; p <= M; ++p) {

        nwds = 0;

        /*
         * Test 500 different message sizes.
         */
        for (j = 0; j < 500; ++j) {

            nwds = (int)((nwds + 1) * 1.016);

            byte = 8 * nwds;

            nloop = (int)(msg_vol / ((double)nwds + 2.0));

            if (nloop > 1000)
                nloop = 1000;

            if (nloop < 20)
                nloop = 20;

            /*
             * Ping-pong between rank 0 and rank p.
             */
            time = ping_pong(buf, byte, p, nloop);

            /*
             * Only rank 0 records the timing.
             */
            if (rank == 0) {
                fprintf(fp, "%8d %12d %12d %12d %15.6e\n",
                        p, nwds, byte, nloop, time);
            }
        }
    }

    if (rank == 0)
        fclose(fp);

    free(buf);

    msg_finalize();

    return 0;
}