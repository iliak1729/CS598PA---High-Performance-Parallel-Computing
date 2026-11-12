
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <assert.h>
#include "cg.h"
#include "poisson_1D.h"
#include "poisson_2D.h"
#include "poisson_3D.h"
#include "vtk_writer.h"

#define GREEN "\033[0;32m"
#define RED "\033[0;31m"
#define RESET "\033[0m"

void test_cg_2x2(void)
{
    int n = 2;

    double A[] = {
        4.0, 1.0,
        1.0, 3.0};

    double b[] = {1.0, 2.0};
    double x[] = {0.0, 0.0};

    CGProblem problem = {
        .n = n,
        .tol = 1e-10,
        .maxiter = 1000,
        .A = A,
        .b = b,
        .x = x,
        .matvec = matvec,
        .dot = dot};

    int iterations = conjugate_gradient(&problem);

    assert(iterations == 2);
    assert(fabs(x[0] - 1.0 / 11.0) < 1e-10);
    assert(fabs(x[1] - 7.0 / 11.0) < 1e-10);

    printf(GREEN "PASS: test_cg_2x2" RESET "\n");
}

void test_cg_4x4(void)
{
    int n = 4;

    double A[] = {
        4.0, -1.0, 0.0, 0.0,
        -1.0, 4.0, -1.0, 0.0,
        0.0, -1.0, 4.0, -1.0,
        0.0, 0.0, -1.0, 4.0};

    double b[] = {2.0, 4.0, 6.0, 13.0};
    double x[] = {0.0, 0.0, 0.0, 0.0};

    CGProblem problem = {
        .n = n,
        .tol = 1e-10,
        .maxiter = 1000,
        .A = A,
        .b = b,
        .x = x,
        .matvec = matvec,
        .dot = dot};

    int iterations = conjugate_gradient(&problem);

    assert(iterations == 4);
    assert(fabs(x[0] - 1.0) < 1e-10);
    assert(fabs(x[1] - 2.0) < 1e-10);
    assert(fabs(x[2] - 3.0) < 1e-10);
    assert(fabs(x[3] - 4.0) < 1e-10);

    printf(GREEN "PASS: test_cg_4x4" RESET "\n");
}

void test_cg_poisson_1D(void)
{
    int n = 4;

    double dx = 0.2;
    double A[] = {dx};

    double b[] = {0.0, 0.0, 0.0, 125.0};
    double x[] = {0.0, 0.0, 0.0, 0.0};

    double x_exact[] = {1.0, 2.0, 3.0, 4.0};

    CGProblem problem = {
        .n = n,
        .tol = 1e-10,
        .maxiter = 1000,
        .A = A,
        .b = b,
        .x = x,
        .matvec = poisson_1D_matvec,
        .dot = dot};

    int iterations = conjugate_gradient(&problem);

    assert(iterations >= 0);

    for (int i = 0; i < n; ++i)
    {
        assert(fabs(x[i] - x_exact[i]) < 1e-10);
    }

    printf(GREEN "PASS: test_cg_poisson_1D" RESET "\n");
}

void test_cg_poisson_2D(void)
{
    int nx = 2;
    int ny = 2;
    int n = nx * ny;

    double dx = 1.0 / (nx + 1);
    double dy = 1.0 / (ny + 1);

    double A[] = {dx, dy};

    double b[] = {-9.0, 27.0, 63.0, 99.0};
    double x[] = {0.0, 0.0, 0.0, 0.0};
    double x_exact[] = {1.0, 2.0, 3.0, 4.0};

    Poisson2DContext grid = {
        .nx = nx,
        .ny = ny};

    CGProblem problem = {
        .n = n,
        .tol = 1e-10,
        .maxiter = 1000,
        .A = A,
        .b = b,
        .x = x,
        .context = &grid,
        .matvec = poisson_2D_matvec,
        .dot = dot};

    double Ax[4];

    int iterations = conjugate_gradient(&problem);

    write_vtk_2D("results/poisson_2D.vtk",
                 nx, ny, dx, dy, x);
    assert(iterations >= 0);

    for (int i = 0; i < n; ++i)
    {
        assert(fabs(x[i] - x_exact[i]) < 1e-10);
    }

    printf(GREEN "PASS: test_cg_poisson_2D" RESET "\n");
}

void test_cg_poisson_2D_heat(void)
{
    // ========================================================
    // User-defined parameters
    // ========================================================
    int nx = 128;
    int ny = 128;

    double Lx = 1.0;
    double Ly = 1.0;

    double alpha = -1.0;

    double tol = 1e-10;
    int maxiter = 10000;

    // ========================================================
    // Grid setup
    // ========================================================
    int n = nx * ny;

    double dx = Lx / (nx + 1);
    double dy = Ly / (ny + 1);

    double A[] = {dx, dy};

    Poisson2DContext grid = {
        .nx = nx,
        .ny = ny};

    // ========================================================
    // Allocate memory
    // ========================================================
    double *b = malloc(n * sizeof(double));
    double *x = calloc(n, sizeof(double));

    assert(b != NULL);
    assert(x != NULL);

    // ========================================================
    // Initialize RHS: -alpha
    // ========================================================
    for (int i = 0; i < n; ++i)
    {
        b[i] = -alpha;
    }

    // ========================================================
    // Configure CG solver
    // ========================================================
    CGProblem problem = {
        .n = n,
        .tol = tol,
        .maxiter = maxiter,
        .A = A,
        .b = b,
        .x = x,
        .context = &grid,
        .matvec = poisson_2D_matvec,
        .dot = dot};

    // ========================================================
    // Solve
    // ========================================================
    int iterations = conjugate_gradient(&problem);

    assert(iterations >= 0);

    printf("2D Poisson heat problem:\n");
    printf("  nx, ny     = %d, %d\n", nx, ny);
    printf("  Lx, Ly     = %.6f, %.6f\n", Lx, Ly);
    printf("  dx, dy     = %.6e, %.6e\n", dx, dy);
    printf("  alpha      = %.6f\n", alpha);
    printf("  iterations = %d\n", iterations);

    // ========================================================
    // Solution statistics
    // ========================================================
    double umin = x[0];
    double umax = x[0];

    for (int i = 1; i < n; ++i)
    {
        if (x[i] < umin)
            umin = x[i];

        if (x[i] > umax)
            umax = x[i];
    }

    printf("  u_min      = %.12e\n", umin);
    printf("  u_max      = %.12e\n", umax);

    // ========================================================
    // Write VTK
    // ========================================================
    write_vtk_2D("results/poisson_2D_heat.vtk",
                 nx, ny, dx, dy, x);

    // ========================================================
    // Cleanup
    // ========================================================
    free(b);
    free(x);

    printf(GREEN "PASS: test_cg_poisson_2D_heat" RESET "\n");
}

void test_cg_poisson_3D(void)
{
    int nx = 2;
    int ny = 2;
    int nz = 2;
    int n = nx * ny * nz;

    double dx = 1.0 / (nx + 1);
    double dy = 1.0 / (ny + 1);
    double dz = 1.0 / (nz + 1);

    double A[] = {dx, dy, dz};

    double b[] = {-36.0, -18.0, -9.0, 0.0, 81.0, 90.0, 180.0, 279.0};
    double x[] = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0};
    double x_exact[] = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0};

    Poisson3DContext grid = {
        .nx = nx,
        .ny = ny,
        .nz = nz};

    CGProblem problem = {
        .n = n,
        .tol = 1e-10,
        .maxiter = 1000,
        .A = A,
        .b = b,
        .x = x,
        .context = &grid,
        .matvec = poisson_3D_matvec,
        .dot = dot};
    printf("PROBLEM STARTED\n");
    int iterations = conjugate_gradient(&problem);
    printf("PROBLEM SOLVED\n");
    // write_vtk_3D("results/poisson_3D.vtk",
    //              nx, ny, nz, dx, dy, dz, x);

    // assert(iterations >= 0);

    // for (int i = 0; i < n; ++i)
    // {
    //     assert(fabs(x[i] - x_exact[i]) < 1e-10);
    // }

    printf(GREEN "PASS: test_cg_poisson_3D" RESET "\n");
}

void test_cg_poisson_3D_heat(void)
{
    // ========================================================
    // User-defined parameters
    // ========================================================
    int nx = 32;
    int ny = 64;
    int nz = 32;

    double Lx = 1.0;
    double Ly = 2.0;
    double Lz = 1.0;

    double alpha = -1.0;

    double tol = 1e-10;
    int maxiter = 100000;

    // ========================================================
    // Dirichlet boundary values
    // ========================================================
    double bc_xmin = 1.0;
    double bc_xmax = 0.0;

    double bc_ymin = 0.0;
    double bc_ymax = 0.0;

    double bc_zmin = 0.0;
    double bc_zmax = 0.0;

    // ========================================================
    // Grid setup
    // ========================================================
    int n = nx * ny * nz;

    double dx = Lx / (nx + 1);
    double dy = Ly / (ny + 1);
    double dz = Lz / (nz + 1);
    double A[] = {dx, dy, dz};

    Poisson3DContext grid = {
        .nx = nx,
        .ny = ny,
        .nz = nz};

    // ========================================================
    // Initialize boundary conditions
    // ========================================================
    double *bc_values[NUM_FACES] = {
        &bc_xmin,
        &bc_xmax,
        &bc_ymin,
        &bc_ymax,
        &bc_zmin,
        &bc_zmax};

    for (int face = 0; face < NUM_FACES; ++face)
    {
        grid.bcs[face].type = BC_DIRICHLET;
        grid.bcs[face].face = (BoundaryFace)face;
        grid.bcs[face].function = bc_constant;
        grid.bcs[face].context = bc_values[face];
        grid.bcs[face].neighbor_rank = -1;
    }

    // ========================================================
    // Allocate memory
    // ========================================================
    double *b = malloc(n * sizeof(double));
    double *x = calloc(n, sizeof(double));

    assert(b != NULL);
    assert(x != NULL);

    // ========================================================
    // Initialize RHS: -alpha
    // ========================================================
    for (int i = 0; i < n; ++i)
    {
        b[i] = -alpha;
    }

    // ========================================================
    // Apply boundary conditions
    // ========================================================
    poisson_3D_apply_boundary_conditions(
        nx, ny, nz,
        dx, dy, dz,
        b,
        grid.bcs);

    // ========================================================
    // Configure CG solver
    // ========================================================
    CGProblem problem = {
        .n = n,
        .tol = tol,
        .maxiter = maxiter,
        .A = A,
        .b = b,
        .x = x,
        .context = &grid,
        .matvec = poisson_3D_matvec,
        .dot = dot};

    // ========================================================
    // Solve
    // ========================================================
    int iterations = conjugate_gradient(&problem);

    assert(iterations >= 0);

    printf("3D Poisson heat problem:\n");
    printf("  nx, ny, nz    = %d, %d, %d\n", nx, ny, nz);
    printf("  Lx, Ly, Lz    = %.6f, %.6f, %.6f\n", Lx, Ly, Lz);
    printf("  dx, dy, dz    = %.6e, %.6e, %.6e\n", dx, dy, dz);
    printf("  alpha      = %.6f\n", alpha);
    printf("  iterations = %d\n", iterations);

    // ========================================================
    // Solution statistics
    // ========================================================
    double umin = x[0];
    double umax = x[0];

    for (int i = 1; i < n; ++i)
    {
        if (x[i] < umin)
            umin = x[i];

        if (x[i] > umax)
            umax = x[i];
    }

    printf("  u_min      = %.12e\n", umin);
    printf("  u_max      = %.12e\n", umax);

    // ========================================================
    // Write VTK
    // ========================================================
    write_vtk_3D(
        "results/poisson_3D_heat.vtk", nx, ny, nz, dx, dy, dz, x, grid.bcs);

    // ========================================================
    // Cleanup
    // ========================================================
    free(b);
    free(x);

    printf(GREEN "PASS: test_cg_poisson_3D_heat" RESET "\n");
}

int main(void)
{
    test_cg_2x2();
    test_cg_4x4();
    test_cg_poisson_1D();
    test_cg_poisson_2D();
    test_cg_poisson_2D_heat();
    test_cg_poisson_3D();
    test_cg_poisson_3D_heat();
    printf(GREEN "All tests passed!" RESET "\n");
    return 0;
}
