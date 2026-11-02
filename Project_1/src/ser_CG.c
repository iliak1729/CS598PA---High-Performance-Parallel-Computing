#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "cg.h"

int main(void)
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

    printf("\nIterations: %d\n", iterations);

    printf("Solution:\n");

    for (int i = 0; i < problem.n; ++i)
    {
        printf("x[%d] = %.12f\n", i, problem.x[i]);
    }

    return 0;
}