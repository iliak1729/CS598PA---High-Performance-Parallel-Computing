/*
From Previous Version:
Cache blocking to maintain A,B hot while C is worked on.
Various BM,BN,BK Values were tried:
BM=64, BN=64, BK=128 = 20.078523 GFLOPS
BM=64, BN=64, BK=64 =  23.140657 GFLOPS
BM=128, BN=64, BK=64 =  23.204842 GFLOPS
BM=64, BN=128, BK=64 =  23.172259 GFLOPS
BM=32, BN=64, BK=64 =  23.113049GFLOPS
BM=128, BN=128, BK=64 =  23.143259 GFLOPS
BM=32, BN=32, BK=32 =  24.774495 GFLOPS
BM=16, BN=16, BK=16 =  28.939642 GFLOPS
BM=8, BN=8, BK=8 =  27.636178 GFLOPS
*/
#define BM 16
#define BN 16
#define BK 16

void dgemm_kernel(
    int m,
    int n,
    int k,
    const double * restrict A,
    const double * restrict B,
    double * restrict C)
{
    int i, j, p;
    int ii, jj, kk;

    /*
     * Initialize C = 0
     */
    for (j = 0; j < n; ++j) {
        for (i = 0; i < m; ++i) {
            C[i + j*m] = 0.0;
        }
    }

    /*
     * Cache blocking
     */
    for (jj = 0; jj < n; jj += BN) {

        int jend = jj + BN;
        if (jend > n)
            jend = n;

        for (kk = 0; kk < k; kk += BK) {

            int kend = kk + BK;
            if (kend > k)
                kend = k;

            for (ii = 0; ii < m; ii += BM) {

                int iend = ii + BM;
                if (iend > m)
                    iend = m;

                /*
                 * 4x4 microkernel
                 */
                for (j = jj; j <= jend - 4; j += 4) {

                    for (i = ii; i <= iend - 4; i += 4) {

                        /*
                         * Load current partial C block.
                         *
                         * This matters because each kk block only
                         * computes part of the complete dot product.
                         */
                        double c00 = C[i     + (j    )*m];
                        double c10 = C[i + 1 + (j    )*m];
                        double c20 = C[i + 2 + (j    )*m];
                        double c30 = C[i + 3 + (j    )*m];

                        double c01 = C[i     + (j + 1)*m];
                        double c11 = C[i + 1 + (j + 1)*m];
                        double c21 = C[i + 2 + (j + 1)*m];
                        double c31 = C[i + 3 + (j + 1)*m];

                        double c02 = C[i     + (j + 2)*m];
                        double c12 = C[i + 1 + (j + 2)*m];
                        double c22 = C[i + 2 + (j + 2)*m];
                        double c32 = C[i + 3 + (j + 2)*m];

                        double c03 = C[i     + (j + 3)*m];
                        double c13 = C[i + 1 + (j + 3)*m];
                        double c23 = C[i + 2 + (j + 3)*m];
                        double c33 = C[i + 3 + (j + 3)*m];

                        /*
                         * Only work over the current k block.
                         */
                        for (p = kk; p < kend; ++p) {

                            double a0 = A[i     + p*m];
                            double a1 = A[i + 1 + p*m];
                            double a2 = A[i + 2 + p*m];
                            double a3 = A[i + 3 + p*m];

                            double b0 = B[p + (j    )*k];
                            double b1 = B[p + (j + 1)*k];
                            double b2 = B[p + (j + 2)*k];
                            double b3 = B[p + (j + 3)*k];

                            c00 += a0 * b0;
                            c10 += a1 * b0;
                            c20 += a2 * b0;
                            c30 += a3 * b0;

                            c01 += a0 * b1;
                            c11 += a1 * b1;
                            c21 += a2 * b1;
                            c31 += a3 * b1;

                            c02 += a0 * b2;
                            c12 += a1 * b2;
                            c22 += a2 * b2;
                            c32 += a3 * b2;

                            c03 += a0 * b3;
                            c13 += a1 * b3;
                            c23 += a2 * b3;
                            c33 += a3 * b3;
                        }

                        /*
                         * Store partial C block.
                         */
                        C[i     + (j    )*m] = c00;
                        C[i + 1 + (j    )*m] = c10;
                        C[i + 2 + (j    )*m] = c20;
                        C[i + 3 + (j    )*m] = c30;

                        C[i     + (j + 1)*m] = c01;
                        C[i + 1 + (j + 1)*m] = c11;
                        C[i + 2 + (j + 1)*m] = c21;
                        C[i + 3 + (j + 1)*m] = c31;

                        C[i     + (j + 2)*m] = c02;
                        C[i + 1 + (j + 2)*m] = c12;
                        C[i + 2 + (j + 2)*m] = c22;
                        C[i + 3 + (j + 2)*m] = c32;

                        C[i     + (j + 3)*m] = c03;
                        C[i + 1 + (j + 3)*m] = c13;
                        C[i + 2 + (j + 3)*m] = c23;
                        C[i + 3 + (j + 3)*m] = c33;
                    }
                }
            }
        }
    }
}