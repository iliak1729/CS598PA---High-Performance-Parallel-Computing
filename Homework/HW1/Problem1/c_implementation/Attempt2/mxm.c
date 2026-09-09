/*
From previous attempt:
Change Loop order to j, p, i to improve cache performance.
Striding is better.
*/
void dgemm_kernel(
    int m,
    int n,
    int k,
    const double *A,
    const double *B,
    double *C ) 
{
    int i,j,p;
    /* Zero C */
    for (j = 0; j < n; ++j) {
        for (i = 0; i < m; ++i) {
            C[i + j*m] = 0.0;
        }
    }

    /* Compute C = A * B */
    for (j = 0; j < n; ++j) {
    for (p = 0; p < k; ++p) {

        double Bpj = B[p + j*k];

        for (i = 0; i < m; ++i) {
            C[i + j*m] += A[i + p*m] * Bpj;
        }
    }
}
}