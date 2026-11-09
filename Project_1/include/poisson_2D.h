#ifndef POISSON_2D_H
#define POISSON_2D_H

typedef struct
{
    int nx;
    int ny;
} Poisson2DContext;

void poisson_2D_matvec(int n, const double *A, const double *x, double *y, const void *context);

#endif
