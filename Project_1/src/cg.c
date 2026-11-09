#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "cg.h"

// Define Dot Product
double dot(const double *a, const double *b, int n)
{
    double sum = 0.0;
    for (int i = 0; i < n; ++i)
    {
        sum += a[i] * b[i];
    }

    return sum;
}

// Matrix Vector Multiplication
// y= A*x
void matvec(int n, const double *A, const double *x, double *y, const void *context)
{
    (void)context;
    for (int i = 0; i < n; ++i)
    {
        y[i] = 0.0;
        for (int j = 0; j < n; j++)
        {
            y[i] += A[i * n + j] * x[j];
        }
    }
}

// Conjugate Gradient Algorithm from Saad 6.18
// integer return flags
// Returns number of iterations
int conjugate_gradient(const CGProblem *problem)
{
    // Unpack
    int n = problem->n;
    double tol = problem->tol;
    int maxiter = problem->maxiter;

    const double *A = problem->A;
    const double *b = problem->b;
    double *x = problem->x;
    // Allocae Working variables
    double *r = malloc(n * sizeof(*r));
    double *p = malloc(n * sizeof(*p));
    double *Ap = malloc(n * sizeof(*Ap));

    if (!r || !p || !Ap)
    {
        fprintf(stderr, "Memory allocation failed\n");
        free(r);
        free(p);
        free(Ap);
        return -1;
    }
    // Initialize x to be all zeros
    for (int i = 0; i < n; ++i)
    {
        x[i] = 0.0;
    }
    // Initial Residual - Store matrix multiplication in Ap for now
    problem->matvec(n, A, x, Ap, problem->context);
    double initial_res_mag = 0.0;
    for (int i = 0; i < n; i++)
    {
        r[i] = b[i] - Ap[i];
        p[i] = r[i];
        initial_res_mag = initial_res_mag + r[i] * r[i];
    }
    initial_res_mag = sqrt(initial_res_mag);
    // CG Loop
    double alpha = 0.0;
    double beta = 0.0;
    double sumR = 0.0;
    for (int j = 0; j < maxiter; ++j)
    {
        // Compute Ap
        problem->matvec(n, A, p, Ap, problem->context);
        // Alpha Calc
        alpha = problem->dot(r, r, n) / problem->dot(Ap, p, n);
        // Updates
        for (int i = 0; i < n; ++i)
        {
            // x Update
            x[i] = x[i] + alpha * p[i];
            // Store rk+1 in Ap
            Ap[i] = r[i] - alpha * Ap[i];
        }
        // Beta Calc
        beta = problem->dot(Ap, Ap, n) / problem->dot(r, r, n);
        // Update search direction and residual and residual magnitude
        sumR = 0.0;
        for (int i = 0; i < n; ++i)
        {
            r[i] = Ap[i];
            sumR = sumR + r[i] * r[i];
            p[i] = r[i] + beta * p[i];
        }
        // Check Residual Magnitude
        sumR = sqrt(sumR) / initial_res_mag;
        if (sumR <= tol)
        {
            free(r);
            free(p);
            free(Ap);
            return j + 1;
        }
    }
    // Free
    free(r);
    free(p);
    free(Ap);
    return maxiter;
}