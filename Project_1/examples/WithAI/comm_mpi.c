
/*
 * comm_mpi.c
 *
 * Minimal MPI communication layer for 3D JPCG.
 * All MPI calls are contained in this file.
 *
 * Local arrays include one ghost layer:
 *     (nx+2) x (ny+2) x (nz+2)
 *
 * X is the fastest-varying dimension.
 */

#include <stdio.h>
#include <stdlib.h>
#include <mpi.h>

enum
{
    XMIN = 0,
    XMAX,
    YMIN,
    YMAX,
    ZMIN,
    ZMAX
};

static MPI_Comm cart_comm = MPI_COMM_NULL;

static int rank_id;
static int num_ranks;
static int dims[3];
static int coords[3];
static int neighbors[6];

#define IDX(i, j, k) \
    (((size_t)(k) * (ny + 2) + (j)) * (nx + 2) + (i))

void comm_setup(int *rank, int *size,
                int pdims[3], int pcoords[3],
                int px, int py, int pz)
{
    MPI_Init(NULL, NULL);

    MPI_Comm_size(MPI_COMM_WORLD, &num_ranks);

    // User-specified processor decomposition
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

    MPI_Cart_create(
        MPI_COMM_WORLD, 3, dims, periods,
        0, &cart_comm);

    MPI_Comm_rank(cart_comm, &rank_id);
    MPI_Cart_coords(cart_comm, rank_id, 3, coords);

    MPI_Cart_shift(cart_comm, 0, 1,
                   &neighbors[XMIN], &neighbors[XMAX]);

    MPI_Cart_shift(cart_comm, 1, 1,
                   &neighbors[YMIN], &neighbors[YMAX]);

    MPI_Cart_shift(cart_comm, 2, 1,
                   &neighbors[ZMIN], &neighbors[ZMAX]);

    *rank = rank_id;
    *size = num_ranks;

    for (int d = 0; d < 3; ++d)
    {
        pdims[d] = dims[d];
        pcoords[d] = coords[d];
    }

    if (rank_id == 0)
    {
        printf("\nProcessor decomposition: %d x %d x %d\n",
               dims[0], dims[1], dims[2]);
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

    MPI_Allreduce(
        &value, &result, 1,
        MPI_DOUBLE, MPI_SUM, cart_comm);

    return result;
}

double comm_max(double value)
{
    double result;

    MPI_Allreduce(
        &value, &result, 1,
        MPI_DOUBLE, MPI_MAX, cart_comm);

    return result;
}

double comm_wtime(void)
{
    return MPI_Wtime();
}

void comm_sync(void)
{
    MPI_Barrier(cart_comm);
}

/*
 * Exchange all six faces of a ghosted 3D array.
 *
 * Interior:
 *   i = 1..nx
 *   j = 1..ny
 *   k = 1..nz
 *
 * Physical exterior ghost faces are set to zero.
 *
 * MPI_Sendrecv is used to avoid deadlock.
 */
void update_bdry(double *u, int nx, int ny, int nz)
{
    int counts[3] = {
        ny * nz,
        nx * nz,
        nx * ny};

    int max_count = counts[0];

    if (counts[1] > max_count)
        max_count = counts[1];
    if (counts[2] > max_count)
        max_count = counts[2];

    double *sendbuf = malloc((size_t)max_count * sizeof(double));
    double *recvbuf = malloc((size_t)max_count * sizeof(double));

    if (!sendbuf || !recvbuf)
    {
        fprintf(stderr, "Rank %d: halo allocation failed\n",
                rank_id);
        MPI_Abort(cart_comm, 1);
    }

    /*
     * Zero physical ghost faces.
     * Edges and corners are not needed by the 7-point stencil.
     */
    for (int k = 1; k <= nz; ++k)
        for (int j = 1; j <= ny; ++j)
        {
            u[IDX(0, j, k)] = 0.0;
            u[IDX(nx + 1, j, k)] = 0.0;
        }

    for (int k = 1; k <= nz; ++k)
        for (int i = 1; i <= nx; ++i)
        {
            u[IDX(i, 0, k)] = 0.0;
            u[IDX(i, ny + 1, k)] = 0.0;
        }

    for (int j = 1; j <= ny; ++j)
        for (int i = 1; i <= nx; ++i)
        {
            u[IDX(i, j, 0)] = 0.0;
            u[IDX(i, j, nz + 1)] = 0.0;
        }

    /*
     * X direction
     *
     * Send left interior face, receive right ghost face.
     */
    int n = 0;

    for (int k = 1; k <= nz; ++k)
        for (int j = 1; j <= ny; ++j)
            sendbuf[n++] = u[IDX(1, j, k)];

    MPI_Sendrecv(
        sendbuf, counts[0], MPI_DOUBLE, neighbors[XMIN], 100,
        recvbuf, counts[0], MPI_DOUBLE, neighbors[XMAX], 100,
        cart_comm, MPI_STATUS_IGNORE);

    if (neighbors[XMAX] != MPI_PROC_NULL)
    {
        n = 0;
        for (int k = 1; k <= nz; ++k)
            for (int j = 1; j <= ny; ++j)
                u[IDX(nx + 1, j, k)] = recvbuf[n++];
    }

    /* Send right interior face, receive left ghost face. */
    n = 0;

    for (int k = 1; k <= nz; ++k)
        for (int j = 1; j <= ny; ++j)
            sendbuf[n++] = u[IDX(nx, j, k)];

    MPI_Sendrecv(
        sendbuf, counts[0], MPI_DOUBLE, neighbors[XMAX], 101,
        recvbuf, counts[0], MPI_DOUBLE, neighbors[XMIN], 101,
        cart_comm, MPI_STATUS_IGNORE);

    if (neighbors[XMIN] != MPI_PROC_NULL)
    {
        n = 0;
        for (int k = 1; k <= nz; ++k)
            for (int j = 1; j <= ny; ++j)
                u[IDX(0, j, k)] = recvbuf[n++];
    }

    /*
     * Y direction
     */
    n = 0;

    for (int k = 1; k <= nz; ++k)
        for (int i = 1; i <= nx; ++i)
            sendbuf[n++] = u[IDX(i, 1, k)];

    MPI_Sendrecv(
        sendbuf, counts[1], MPI_DOUBLE, neighbors[YMIN], 200,
        recvbuf, counts[1], MPI_DOUBLE, neighbors[YMAX], 200,
        cart_comm, MPI_STATUS_IGNORE);

    if (neighbors[YMAX] != MPI_PROC_NULL)
    {
        n = 0;
        for (int k = 1; k <= nz; ++k)
            for (int i = 1; i <= nx; ++i)
                u[IDX(i, ny + 1, k)] = recvbuf[n++];
    }

    n = 0;

    for (int k = 1; k <= nz; ++k)
        for (int i = 1; i <= nx; ++i)
            sendbuf[n++] = u[IDX(i, ny, k)];

    MPI_Sendrecv(
        sendbuf, counts[1], MPI_DOUBLE, neighbors[YMAX], 201,
        recvbuf, counts[1], MPI_DOUBLE, neighbors[YMIN], 201,
        cart_comm, MPI_STATUS_IGNORE);

    if (neighbors[YMIN] != MPI_PROC_NULL)
    {
        n = 0;
        for (int k = 1; k <= nz; ++k)
            for (int i = 1; i <= nx; ++i)
                u[IDX(i, 0, k)] = recvbuf[n++];
    }

    /*
     * Z direction
     */
    n = 0;

    for (int j = 1; j <= ny; ++j)
        for (int i = 1; i <= nx; ++i)
            sendbuf[n++] = u[IDX(i, j, 1)];

    MPI_Sendrecv(
        sendbuf, counts[2], MPI_DOUBLE, neighbors[ZMIN], 300,
        recvbuf, counts[2], MPI_DOUBLE, neighbors[ZMAX], 300,
        cart_comm, MPI_STATUS_IGNORE);

    if (neighbors[ZMAX] != MPI_PROC_NULL)
    {
        n = 0;
        for (int j = 1; j <= ny; ++j)
            for (int i = 1; i <= nx; ++i)
                u[IDX(i, j, nz + 1)] = recvbuf[n++];
    }

    n = 0;

    for (int j = 1; j <= ny; ++j)
        for (int i = 1; i <= nx; ++i)
            sendbuf[n++] = u[IDX(i, j, nz)];

    MPI_Sendrecv(
        sendbuf, counts[2], MPI_DOUBLE, neighbors[ZMAX], 301,
        recvbuf, counts[2], MPI_DOUBLE, neighbors[ZMIN], 301,
        cart_comm, MPI_STATUS_IGNORE);

    if (neighbors[ZMIN] != MPI_PROC_NULL)
    {
        n = 0;
        for (int j = 1; j <= ny; ++j)
            for (int i = 1; i <= nx; ++i)
                u[IDX(i, j, 0)] = recvbuf[n++];
    }

    free(sendbuf);
    free(recvbuf);
}

#undef IDX
