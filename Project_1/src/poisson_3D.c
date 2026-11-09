#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "poisson_3D.h"

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