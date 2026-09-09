#include <stdio.h>
#include <stdlib.h>
#include <time.h>

/* Matrix multiplication function from mxm.c */
void dgemm_kernel(
    int m,
    int n,
    int k,
    const double *A,
    const double *B,
    double *C
);

int main(void)
{
     /* Open output file */
    FILE *log = fopen("benchmark.log", "w");

    if (log == NULL) {
        return 1;
    }
    printf("%10s %15s %15s\n", "N", "Time", "Gflops");
    fflush(log);
    for (int N = 8; N <= 2000; N += 32) {

       

        /* Allocate matrices */
        double *A = malloc(N * N * sizeof(double));
        double *B = malloc(N * N * sizeof(double));
        double *C = malloc(N * N * sizeof(double));

        /* Fill A and B with random numbers */
        for (int i = 0; i < N * N; ++i) {
            A[i] = (double)rand() / RAND_MAX;
            B[i] = (double)rand() / RAND_MAX;
        }

        /* Start timer */
        struct timespec start, end;

        clock_gettime(CLOCK_MONOTONIC, &start);


        /* C = A * B 10 times */
        for (int i = 0; i < 10; ++i) {
            dgemm_kernel(N, N, N, A, B, C);
        }

        /* Stop timer */
        clock_gettime(CLOCK_MONOTONIC, &end);

        double time =
            (end.tv_sec - start.tv_sec) +
            (end.tv_nsec - start.tv_nsec) * 1e-9;

        time /= 10.0;
        /* COMPUTE GLOPS */
        int N3 = N * N * N;
        double gflops = (2.0 * N3 / time) / 1e9;
         /* Write to log file */
        fprintf(log, "%d %f %f\n", N, time, gflops);
        printf("%d %f %f\n", N, time, gflops);
        fflush(log);
        /* Free memory */
        free(A);
        free(B);
        free(C);
    }
    fclose(log);

    return 0;
}