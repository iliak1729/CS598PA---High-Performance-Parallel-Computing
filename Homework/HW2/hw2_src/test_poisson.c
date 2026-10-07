/* Rectangular Dirichlet Poisson: discrete exactness + O(h^2) convergence. */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "poisson.h"
#include "msg.h"
#ifndef M_PI
#define M_PI 3.141592653589793238462643383279502884
#endif

static double exact_u(double x, double y, double Lx, double Ly)
{
    return sin(M_PI*x/Lx)*sin(2.0*M_PI*y/Ly);
}

/* -Laplacian of the above */
static double rhs_f(double x, double y, double Lx, double Ly)
{
    const double c = M_PI*M_PI/(Lx*Lx) + 4.0*M_PI*M_PI/(Ly*Ly);
    return c*exact_u(x,y,Lx,Ly);
}

int main(int argc, char **argv)
{
    int Nx=128, Ny=512, i,j;
    double Lx=2.0, Ly=1.0, e,emax;
    poisson_plan p;
    double *F,*U,*Uex,*Ud,*Fd;

    msg_init(&argc,&argv);
    if (msg_rank()==0) printf("running on %d rank(s)\n", num_ranks());

    if (argc>1) Nx = atoi(argv[1]);
    if (argc>2) Ny = atoi(argv[2]);
    if (argc>3) Lx = atof(argv[3]);
    if (argc>4) Ly = atof(argv[4]);
    int nx=Nx-1;
    int ny=Ny-1;

    if (poisson_plan_init(&p,nx,ny,Lx,Ly)) return 1;
    
    const int local_nx = p.local_nx;
    const int local_size = local_nx*ny;
    F  =(double*)malloc((size_t)local_size*sizeof(double));
    U  =(double*)malloc((size_t)local_size*sizeof(double));
    Uex=(double*)malloc((size_t)local_size*sizeof(double));
    Ud =(double*)malloc((size_t)local_size*sizeof(double));
    Fd =(double*)malloc((size_t)local_size*sizeof(double));
    if (!F||!U||!Uex||!Ud||!Fd) return 2;

    if (msg_rank()==0) {
        printf("domain  [0,%g] x [0,%g]\n",Lx,Ly);
        printf("nx ny   = %d %d      (Nx Ny = %d %d)\n",nx,ny,Nx,Ny);
        printf("hx hy   = %.6e %.6e\n",p.hx,p.hy);
    }
    double global_emax;
    /* ---- test 1: exact inversion of the DISCRETE operator ---------- */
    srand(999);
    for (i=0; i<local_size; ++i) Ud[i]=2.0*((double)rand()/(double)RAND_MAX)-1.0;
    poisson_residual_op(&p,Ud,Fd);
    poisson_solve(&p,Fd,U);
    poisson_solve(&p,Fd,U);
    emax=0.0;
    for (i=0; i<local_size; ++i) { e=fabs(U[i]-Ud[i]); if (e>emax) emax=e; }
    
    gmax_double(&emax,&global_emax,1);

    if (msg_rank()==0){
        printf("\ndiscrete solve  max|U - Uexact_h|      = %.6e   (expect ~roundoff)\n",global_emax);
        printf("  total     = %.6e\n", p.time_total);
        printf("  fst       = %.6e\n", p.time_fst);
        printf("  transpose = %.6e\n", p.time_transpose);
        printf("  divide    = %.6e\n", p.time_divide);
    }

    /* ---- test 2: continuous solution, expect O(h^2) ---------------- */
    for (j=0; j<ny; ++j) {
        double y=(double)(j+1)*p.hy;
        for (i=0; i<local_nx; ++i) {
            int global_i =p.x_start + i;
            double x=(double)(global_i+1)*p.hx;
            F  [i+j*local_nx]=rhs_f  (x,y,Lx,Ly);
            Uex[i+j*local_nx]=exact_u(x,y,Lx,Ly);
        }
    }
    poisson_solve(&p,F,U);
    emax=0.0;
    for (i=0; i<local_size; ++i) { e=fabs(U[i]-Uex[i]); if (e>emax) emax=e; }

    gmax_double(&emax,&global_emax,1);

    double ep = global_emax*16;
    double em = global_emax/16;
    if (msg_rank()==0)
        printf("continuous      max|U - u(x,y)|        = %.6e  %.6e  %.6e  (expect O(h^2))\n",global_emax,em,ep);

    poisson_plan_free(&p);
    free(F); free(U); free(Uex); free(Ud); free(Fd);
    msg_finalize();
    return 0;
}
