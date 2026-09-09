void dgemm_kernel(
    int m,
    int n,
    int k,
    const double *A,
    const double *B,
    double *C ) 
{
    int i,j,p;
    for(j=0;j<n;++j) {
        for (i=0;i<m;++i) {
            double cij = 0.0;
            for (p=0;p<k;++p) {
                cij += A[i + p*m] * B[p + j*k];
            }
            C[i + j*m] = cij;
        }
    }
}