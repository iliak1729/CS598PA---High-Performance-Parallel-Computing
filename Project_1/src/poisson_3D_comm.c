#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "poisson_3D.h"
#include <mpi.h>

static MPI_Comm cart_comm = MPI_COMM_NULL;
static int rank_id;
static int num_ranks;
static int dims[3];
static int coords[3];
static int neighbors[6];

#define IDX(i, j, k) \
    (((size_t)(k) * (ny + 2) + (j)) * (nx + 2) + (i))

void comm_setup(int *rank, int *size, int pdmins[3], int pcoords[3], int px, int py, int pz)
{
    MPI_Init(NULL, NULL);

    MPI_Comm_size(MPI_COMM_WORLD, &num_ranks);

    // Domain Decomposition
    dims[0] = px;
    dims[1] = py;
    dims[2] = pz;

    // Verify decomposition matches number of MPI ranks
    if (px <= 0 || py <= 0 || pz <= 0 ||
        (long long)px * py * pz != num_ranks)
    {
        fprintf(stderr,
                "Invalid processor decomposition: %d x %d x %d "
                "for %d MPI ranks\n",
                px, py, pz, num_ranks);

        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    int periods[3] = {0, 0, 0}
}