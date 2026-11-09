#ifndef CG_H
#define CG_H

typedef struct
{
    int n;
    double tol;
    int maxiter;

    const double *A;
    const double *b;
    double *x;

    void *context;

    void (*matvec)(int, const double *, const double *, double *, const void *);
    double (*dot)(const double *, const double *, int);

} CGProblem;

// Function declarations
double dot(const double *a, const double *b, int n);

void matvec(int n, const double *A,
            const double *x, double *y, const void *context);

int conjugate_gradient(const CGProblem *problem);

#endif