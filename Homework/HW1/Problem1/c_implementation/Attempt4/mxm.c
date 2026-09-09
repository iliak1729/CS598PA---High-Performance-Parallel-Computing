/*
From Previous Version:
Microkernel optimization to do 4x4 block multiplication at a time.

*/
void dgemm_kernel(
    int m,
    int n,
    int k,
    const double * restrict A,
    const double * restrict B,
    double * restrict C)
{
    int i, j, p;

    for (j = 0; j <= n - 4; j += 4) {
        for (i = 0; i <= m - 4; i += 4) {

            double c00 = 0.0, c10 = 0.0, c20 = 0.0, c30 = 0.0;
            double c01 = 0.0, c11 = 0.0, c21 = 0.0, c31 = 0.0;
            double c02 = 0.0, c12 = 0.0, c22 = 0.0, c32 = 0.0;
            double c03 = 0.0, c13 = 0.0, c23 = 0.0, c33 = 0.0;

            for (p = 0; p < k; ++p) {

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