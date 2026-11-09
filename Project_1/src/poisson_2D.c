#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "poisson_2D.h"

void poisson_2D_matvec(int n, const double *A, const double *x, double *y, const void *context)
{
    const Poisson2DContext *grid = context;

    int nx = grid->nx;
    int ny = grid->ny;

    double dx = A[0];
    double dy = A[1];
    double inv_dx2 = 1.0 / (dx * dx);
    double inv_dy2 = 1.0 / (dy * dy);
    for (int j = 0; j < ny; ++j) // x Loop
    {
        for (int i = 0; i < nx; ++i)
        {
            // Index
            int l = nx * j + i;
            // Operator
            // Diagonal Component
            y[l] = (2.0 * inv_dx2 + 2.0 * inv_dy2) * x[l];
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
        }
    }
}