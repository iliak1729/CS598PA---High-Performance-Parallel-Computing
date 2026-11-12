#ifndef POISSON_3D_PAR_H
#define POISSON_3D_PAR_H

typedef struct
{
    int nx, ny, nz // Local Dimensions
        int global_nx,
        global_ny, global_nz;

    int start_x, start_y, start_z;
    double dx, dy, dz;
} Grid3D;

void setup_par_domains(Grid3D *g, int global_nx, int global_ny, int global_nz, const int pdims[3], const int pcoords[3]);

double grid_dot_product(const double *x, const double *y, const Grid3D *g);

// w = A*p
void poisson_3D_par_matvec(double *w, double *p, const Grid3D *g);

// x = y + a*x
void add2s1(double *x, const double *y, double a, const Grid3D *g);

void add2s2(double *x, const double *y, double a, const Grid3D *g);

void apply_preconditioner(double *z, const double *r, const Grid3D *g);

int pcg_solve(double *x, const double *b, const Grid3D *g, int maxit, double *tol, int rank);
#endif
