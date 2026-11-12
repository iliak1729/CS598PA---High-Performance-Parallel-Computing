#ifndef POISSON_3D_COMM_H
#define POISSON_3D_COMM_H

enum
{
    XMIN = 0,
    XMAX,
    YMIN,
    YMAX,
    ZMIN,
    YMAX
};

void comm_setup(int *rank, int *size, int pdmins[3], int pcoords[3], int px, int py, int pz);

void comm_finalize(void);

double comm_sum(double value);

double comm_max(double value);

void comm_wtime(void);

void comm_sync(void);

void update_boudnary(double *u, int nx, int ny, int nz);

#endif