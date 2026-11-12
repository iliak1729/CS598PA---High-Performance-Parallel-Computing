#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "poisson_3D.h"

/**
 * Homogeneous Dirichlet boundary condition
 * u = 0
 */
double bc_zero(double x, double y, double z,
               const void *context)
{
    (void)x;
    (void)y;
    (void)z;
    (void)context;

    return 0.0;
}

/**
 * Constant Dirichlet boundary condition
 * u = C
 *
 * context points to a double containing C.
 */
double bc_constant(double x, double y, double z,
                   const void *context)
{
    (void)x;
    (void)y;
    (void)z;

    return *(const double *)context;
}

/**
 * Linear Dirichlet boundary condition
 * u = x + y + z
 */
double bc_linear(double x, double y, double z,
                 const void *context)
{
    (void)context;

    return x + y + z;
}

void poisson_3D_matvec(int n, const double *A, const double *x, double *y, const void *context)
{
    const Poisson3DContext *grid = context;

    int nx = grid->nx;
    int ny = grid->ny;
    int nz = grid->nz;

    double dx = A[0];
    double dy = A[1];
    double dz = A[2];
    double inv_dx2 = 1.0 / (dx * dx);
    double inv_dy2 = 1.0 / (dy * dy);
    double inv_dz2 = 1.0 / (dz * dz);
    for (int k = 0; k < nz; ++k)
    {
        for (int j = 0; j < ny; ++j) // y loop
        {
            for (int i = 0; i < nx; ++i) // x loop
            {
                // Index
                int l = nx * ny * k + nx * j + i;
                // Operator
                // Diagonal Component
                y[l] = (2.0 * inv_dx2 + 2.0 * inv_dy2 + 2.0 * inv_dz2) * x[l];
                // X Derivative
                if (i > 0)
                {
                    y[l] = y[l] - x[l - 1] * inv_dx2;
                }
                if (i < nx - 1)
                {
                    y[l] = y[l] - x[l + 1] * inv_dx2;
                }
                // Y Derivative
                if (j > 0)
                {
                    y[l] = y[l] - x[l - nx] * inv_dy2;
                }
                if (j < ny - 1)
                {
                    y[l] = y[l] - x[l + nx] * inv_dy2;
                }
                // Z Deriative
                if (k > 0)
                {
                    y[l] = y[l] - x[l - nx * ny] * inv_dz2;
                }
                if (k < nz - 1)
                {
                    y[l] = y[l] - x[l + nx * ny] * inv_dz2;
                }
            }
        }
    }
}

void poisson_3D_apply_boundary_conditions(int nx, int ny, int nz,
                                          double dx, double dy, double dz,
                                          double *b,
                                          const PoissonBC bcs[NUM_FACES])
{
    // Domain
    const double Lx = (nx + 1) * dx;
    const double Ly = (ny + 1) * dy;
    const double Lz = (nz + 1) * dz;

    const double inv_dx2 = 1.0 / (dx * dx);
    const double inv_dy2 = 1.0 / (dy * dy);
    const double inv_dz2 = 1.0 / (dz * dz);

    for (int face = 0; face < NUM_FACES; ++face)
    {
        const PoissonBC *bc = &bcs[face];
        int ni, nj;
        double scale;
        switch (face)
        {
        case XMIN:
        case XMAX:
            ni = ny;
            nj = nz;
            scale = inv_dx2;
            break;
        case YMIN:
        case YMAX:
            ni = nx;
            nj = nz;
            scale = inv_dy2;
            break;
        case ZMIN:
        case ZMAX:
            ni = nx;
            nj = ny;
            scale = inv_dz2;
            break;
        default:
            fprintf(stderr, "Invalid face\n");
            exit(EXIT_FAILURE);
        }

        // Loop over the boundary face
        for (int a = 0; a < ni; ++a)
        {
            for (int c = 0; c < nj; ++c)
            {
                int i, j, k;
                double x, y, z;
                // Locate the interior point and boundary coordinate
                switch (face)
                {
                case XMIN:
                    i = 0;
                    j = a;
                    k = c;
                    x = 0.0;
                    y = (j + 1) * dy;
                    z = (k + 1) * dz;
                    break;

                case XMAX:
                    i = nx - 1;
                    j = a;
                    k = c;
                    x = Lx;
                    y = (j + 1) * dy;
                    z = (k + 1) * dz;
                    break;

                case YMIN:
                    i = a;
                    j = 0;
                    k = c;
                    x = (i + 1) * dx;
                    y = 0.0;
                    z = (k + 1) * dz;
                    break;

                case YMAX:
                    i = a;
                    j = ny - 1;
                    k = c;
                    x = (i + 1) * dx;
                    y = Ly;
                    z = (k + 1) * dz;
                    break;

                case ZMIN:
                    i = a;
                    j = c;
                    k = 0;
                    x = (i + 1) * dx;
                    y = (j + 1) * dy;
                    z = 0.0;
                    break;

                case ZMAX:
                    i = a;
                    j = c;
                    k = nz - 1;
                    x = (i + 1) * dx;
                    y = (j + 1) * dy;
                    z = Lz;
                    break;

                default:
                    abort();
                }

                int l = k * nx * ny + j * nx + i;

                // Apply BC
                switch (bc->type)
                {
                case BC_DIRICHLET:
                    b[l] += scale * bc->function(x, y, z, bc->context);
                    break;
                case BC_NEUMANN:
                    fprintf(stderr,
                            "Neumann not implemented\n");
                    exit(EXIT_FAILURE);

                case BC_COMM:
                    fprintf(stderr,
                            "Communication not implemented\n");
                    exit(EXIT_FAILURE);

                default:
                    fprintf(stderr,
                            "Unknown boundary condition\n");
                    exit(EXIT_FAILURE);
                }
            }
        }
    }
}