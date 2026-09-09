#include "msg.h"

/*
 * Perform nloop ping-pong exchanges between rank 0 and rank p.
 *
 * buf      : message buffer
 * nbytes   : number of bytes in the message
 * p        : partner rank
 * nloop    : number of ping-pong repetitions
 *
 * Returns:
 *   Average round-trip time per ping-pong exchange.
 */
double ping_pong(void *buf, int nbytes, int p, int nloop)
{
    int rank = msg_rank();
    double t0 = 0.0;
    double t1 = 0.0;
    int i;

    int nwarmup = 10;

    /*
     * Synchronize before warm-up.
     */
    msg_barrier();

    /*
     * Warm-up ping-pongs -- NOT TIMED.
     */
    for (i = 0; i < nwarmup; ++i) {

        if (p == 0) {

            if (rank == 0) {
                irecv(0, buf, nbytes, 100);
                isend(0, buf, nbytes, 100);
                msgwait();
            }

        } else {

            if (rank == 0) {

                isend(p, buf, nbytes, 100);
                msgwait();

                irecv(p, buf, nbytes, 101);
                msgwait();

            } else if (rank == p) {

                irecv(0, buf, nbytes, 100);
                msgwait();

                isend(0, buf, nbytes, 101);
                msgwait();
            }
        }
    }

    /*
     * Make sure warm-up is completely finished.
     */
    msg_barrier();

    /*
     * Only rank 0 needs to time the exchange.
     */
    if (rank == 0)
        t0 = msg_wtime();

    for (i = 0; i < nloop; ++i) {

        if (p == 0) {
            /*
             * Self ping-pong.
             *
             * Rank 0 sends a message to itself and receives it.
             */
            if (rank == 0) {
                irecv(0, buf, nbytes, 100);
                isend(0, buf, nbytes, 100);
                msgwait();
            }

        } else {

            /*
             * Normal ping-pong between rank 0 and rank p.
             */
            if (rank == 0) {

                /* Ping: rank 0 -> rank p */
                isend(p, buf, nbytes, 100);
                msgwait();

                /* Pong: rank p -> rank 0 */
                irecv(p, buf, nbytes, 101);
                msgwait();

            } else if (rank == p) {

                /* Receive ping from rank 0 */
                irecv(0, buf, nbytes, 100);
                msgwait();

                /* Send pong back to rank 0 */
                isend(0, buf, nbytes, 101);
                msgwait();
            }
        }
    }

    if (rank == 0) {
        t1 = msg_wtime();
        return (t1 - t0) / (double)nloop;
    }

    return 0.0;
}
