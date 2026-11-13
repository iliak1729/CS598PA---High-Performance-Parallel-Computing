#ifndef POISSON_3D_H
#define POISSON_3D_H
typedef enum
{
    BC_DIRICHLET,
    BC_COMM,
    BC_NEUMANN
} BoundaryType;

typedef enum
{
    XMIN = 0,
    XMAX,
    YMIN,
    YMAX,
    ZMIN,
    ZMAX,
    NUM_FACES
} BoundaryFace;

typedef double (*BoundaryFunction)(
    double x, double y, double z,
    const void *context);
typedef struct
{
    // Boundary Info
    BoundaryType type;
    BoundaryFace face;
    // Physical Data
    BoundaryFunction function;
    const void *context;
    // In case we have Com
    int neighbor_rank;
} PoissonBC;

typedef struct
{
    int nx;
    int ny;
    int nz;

    PoissonBC bcs[NUM_FACES];
} Poisson3DContext;

void poisson_3D_matvec(int n, const double *A, const double *x, double *y, const void *context);

void poisson_3D_apply_boundary_conditions(int nx, int ny, int nz, double dx, double dy, double dz,
                                          double *b, const PoissonBC bcs[NUM_FACES]);

double bc_zero(double x, double y, double z,
               const void *context);

double bc_constant(double x, double y, double z,
                   const void *context);

double bc_linear(double x, double y, double z,
                 const void *context);
#endif
