#ifndef POISSON_3D_H
#define POISSON_3D_H

typedef struct
{
    int nx;
    int ny;
    int nz;
} Poisson3DContext;

void poisson_3D_matvec(int n, const double *A, const double *x, double *y, const void *context);

#endif
