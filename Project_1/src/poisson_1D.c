#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "poisson_1D.h"

void poisson_1D_matvec(int n, const double *A, const double *x, double *y, const void *context)
{
    (void)context;
    double dx = A[0];
    double inv_dx2 = 1.0 / (dx * dx);

    for (int i = 0; i < n; ++i)
    {
        y[i] = 2.0 * x[i];
        if (i > 0)
            y[i] = y[i] - x[i - 1];
        if (i < n - 1)
            y[i] = y[i] - x[i + 1];
        y[i] = y[i] * inv_dx2;
    }
}