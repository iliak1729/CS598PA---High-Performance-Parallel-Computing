#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "poisson_3D.h"
#include <mpi.h>
#include "poisson_3D_comm.h"

static MPI_Comm cart_comm = MPI_COMM_NULL;
static int rank_id;
static int num_ranks;
static int dims[3];
static int coords[3];
static int neighbors[6];

#define IDX(i, j, k) \
    (((size_t)(k) * (ny + 2) + (j)) * (nx + 2) + (i))

void comm_setup(int *rank, int *size, int pdims[3], int pcoords[3], int px, int py, int pz)
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

    int periods[3] = {0, 0, 0};

    MPI_Cart_create(MPI_COMM_WORLD, 3, dims, periods, 0, &cart_comm);

    MPI_Comm_rank(cart_comm, &rank_id);
    MPI_Cart_coords(cart_comm, rank_id, 3, coords);

    MPI_Cart_shift(cart_comm, 0, 1, &neighbors[XMIN], &neighbors[XMAX]);

    MPI_Cart_shift(cart_comm, 1, 1, &neighbors[YMIN], &neighbors[YMAX]);

    MPI_Cart_shift(cart_comm, 2, 1, &neighbors[ZMIN], &neighbors[ZMAX]);

    *rank = rank_id;
    *size = num_ranks;

    for (int d = 0; d < 3; ++d)
    {
        pdims[d] = dims[d];
        pcoords[d] = coords[d];
    }

    if (rank_id == 0)
    {
        printf("\nProcessor decomposition: %d x %d x %d\n", dims[0], dims[1],
               dims[2]);
    }
}

void comm_finalize(void)
{
    MPI_Comm_free(&cart_comm);
    MPI_Finalize();
}

double comm_sum(double value)
{
    double result;

    MPI_Allreduce(&value, &result, 1, MPI_DOUBLE, MPI_SUM, cart_comm);

    return result;
}

double comm_max(double value)
{
    double result;

    MPI_Allreduce(&value, &result, 1, MPI_DOUBLE, MPI_MAX, cart_comm);

    return result;
}

double comm_wtime(void) { return MPI_Wtime(); }

void comm_sync(void) { MPI_Barrier(cart_comm); }

void update_boudnary(double *u, int nx, int ny, int nz)
{
    int counts[6] = {
        ny * nz, // XMIN
        ny * nz, // XMAX
        nx * nz, // YMIN
        nx * nz, // YMAX
        nx * ny, // ZMIN
        nx * ny  // ZMAX
    };

    double *sendbuf[6];
    double *recvbuf[6];

    MPI_Request requests[12];
    // ALLOCATE BUFFERS
    for (int d = 0; d < 6; ++d)
    {
        sendbuf[d] = malloc((size_t)counts[d] * sizeof(double));
        recvbuf[d] = malloc((size_t)counts[d] * sizeof(double));

        if (!sendbuf[d] || !recvbuf[d])
        {
            fprintf(stderr, "Rank %d: halo allocation failed\n", rank_id);

            MPI_Abort(cart_comm, 1);
        }
    }

    // PHYSICAL BOUNDARIES

    // X faces
    for (int k = 1; k <= nz; ++k)
    {
        for (int j = 1; j <= ny; ++j)
        {
            u[IDX(0, j, k)] = 0.0;
            u[IDX(nx + 1, j, k)] = 0.0;
        }
    }
    // Y faces
    for (int k = 1; k <= nz; ++k)
    {
        for (int i = 1; i <= nx; ++i)
        {
            u[IDX(i, 0, k)] = 0.0;
            u[IDX(i, ny + 1, k)] = 0.0;
        }
    }
    // Z faces
    for (int j = 1; j <= ny; ++j)
    {
        for (int i = 1; i <= nx; ++i)
        {
            u[IDX(i, j, 0)] = 0.0;
            u[IDX(i, j, nz + 1)] = 0.0;
        }
    }

    // COMMUNICATED BOUNDARIES

    // Pack X
    int n = 0;
    for (int k = 1; k <= nz; ++k)
    {
        for (int j = 1; j <= ny; ++j)
        {
            sendbuf[XMIN][n] = u[IDX(1, j, k)];
            sendbuf[XMAX][n] = u[IDX(nx, j, k)];
            ++n;
        }
    }

    // Pack Y
    n = 0;

    for (int k = 1; k <= nz; ++k)
        for (int i = 1; i <= nx; ++i)
        {
            sendbuf[YMIN][n] = u[IDX(i, 1, k)];
            sendbuf[YMAX][n] = u[IDX(i, ny, k)];
            ++n;
        }

    // Pack Z
    n = 0;
    for (int j = 1; j <= ny; ++j)
    {
        for (int i = 1; i <= nx; ++i)
        {
            sendbuf[ZMIN][n] = u[IDX(i, j, 1)];
            sendbuf[ZMAX][n] = u[IDX(i, j, nz)];
            ++n;
        }
    }
    // Post Recieves
    int req = 0;
    for (int d = 0; d < 6; ++d)
    {
        MPI_Irecv(recvbuf[d], counts[d], MPI_DOUBLE, neighbors[d], d, cart_comm,
                  &requests[req++]);
    }

    // Post Sends
    int opposite[6] = {XMAX, XMIN, YMAX, YMIN, ZMAX, ZMIN};

    for (int d = 0; d < 6; ++d)
    {
        MPI_Isend(sendbuf[d], counts[d], MPI_DOUBLE, neighbors[d], opposite[d],
                  cart_comm, &requests[req++]);
    }

    // Wait
    MPI_Waitall(12, requests, MPI_STATUSES_IGNORE);

    // Unpack X
    n = 0;
    for (int k = 1; k <= nz; ++k)
    {
        for (int j = 1; j <= ny; ++j)
        {
            if (neighbors[XMIN] != MPI_PROC_NULL)
                u[IDX(0, j, k)] = recvbuf[XMIN][n];

            if (neighbors[XMAX] != MPI_PROC_NULL)
                u[IDX(nx + 1, j, k)] = recvbuf[XMAX][n];

            ++n;
        }
    }

    // Unpack Y
    n = 0;
    for (int k = 1; k <= nz; ++k)
    {
        for (int i = 1; i <= nx; ++i)
        {
            if (neighbors[YMIN] != MPI_PROC_NULL)
                u[IDX(i, 0, k)] = recvbuf[YMIN][n];

            if (neighbors[YMAX] != MPI_PROC_NULL)
                u[IDX(i, ny + 1, k)] = recvbuf[YMAX][n];

            ++n;
        }
    }
    // Unpack Z
    n = 0;
    for (int j = 1; j <= ny; ++j)
    {
        for (int i = 1; i <= nx; ++i)
        {
            if (neighbors[ZMIN] != MPI_PROC_NULL)
                u[IDX(i, j, 0)] = recvbuf[ZMIN][n];

            if (neighbors[ZMAX] != MPI_PROC_NULL)
                u[IDX(i, j, nz + 1)] = recvbuf[ZMAX][n];

            ++n;
        }
    }
    // Free
    for (int d = 0; d < 6; ++d)
    {
        free(sendbuf[d]);
        free(recvbuf[d]);
    }
}