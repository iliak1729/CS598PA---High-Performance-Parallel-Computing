
#include <stdio.h>
#include <stdlib.h>
#include "vtk_writer.h"
#include "poisson_3D.h"

void write_vtk_2D(const char *filename,
                  int nx, int ny,
                  double dx, double dy,
                  const double *u)
{
    FILE *fp = fopen(filename, "w");

    if (fp == NULL)
    {
        perror("Error opening VTK file");
        return;
    }

    // Include boundary nodes
    int Nx = nx + 2;
    int Ny = ny + 2;

    fprintf(fp, "# vtk DataFile Version 3.0\n");
    fprintf(fp, "2D Poisson Solution\n");
    fprintf(fp, "ASCII\n");
    fprintf(fp, "DATASET STRUCTURED_POINTS\n");

    fprintf(fp, "DIMENSIONS %d %d 1\n", Nx, Ny);
    fprintf(fp, "ORIGIN 0.0 0.0 0.0\n");
    fprintf(fp, "SPACING %.15g %.15g 1.0\n", dx, dy);

    fprintf(fp, "POINT_DATA %d\n", Nx * Ny);
    fprintf(fp, "SCALARS u double 1\n");
    fprintf(fp, "LOOKUP_TABLE default\n");

    for (int j = 0; j < Ny; ++j)
    {
        for (int i = 0; i < Nx; ++i)
        {
            double value = 0.0;

            // Interior points
            if (i > 0 && i < Nx - 1 &&
                j > 0 && j < Ny - 1)
            {
                int l = (j - 1) * nx + (i - 1);
                value = u[l];
            }

            fprintf(fp, "%.15e\n", value);
        }
    }

    fclose(fp);

    printf("VTK file written: %s\n", filename);
}

void write_vtk_3D(const char *filename, int nx, int ny, int nz,
                  double dx, double dy, double dz, const double *u,
                  const PoissonBC bcs[NUM_FACES])
{
    FILE *fp = fopen(filename, "w");

    if (fp == NULL)
    {
        perror("Error opening VTK file");
        return;
    }

    // Include boundary nodes
    int Nx = nx + 2;
    int Ny = ny + 2;
    int Nz = nz + 2;

    fprintf(fp, "# vtk DataFile Version 3.0\n");
    fprintf(fp, "3D Poisson Solution\n");
    fprintf(fp, "ASCII\n");
    fprintf(fp, "DATASET STRUCTURED_POINTS\n");

    fprintf(fp, "DIMENSIONS %d %d %d\n", Nx, Ny, Nz);
    fprintf(fp, "ORIGIN 0.0 0.0 0.0\n");
    fprintf(fp, "SPACING %.15g %.15g %.15g\n", dx, dy, dz);

    fprintf(fp, "POINT_DATA %d\n", Nx * Ny * Nz);
    fprintf(fp, "SCALARS u double 1\n");
    fprintf(fp, "LOOKUP_TABLE default\n");

    for (int k = 0; k < Nz; ++k)
    {
        for (int j = 0; j < Ny; ++j)
        {
            for (int i = 0; i < Nx; ++i)
            {
                double value = 0.0;

                double x = i * dx;
                double y = j * dy;
                double z = k * dz;

                // Interior points
                if (i > 0 && i < Nx - 1 &&
                    j > 0 && j < Ny - 1 &&
                    k > 0 && k < Nz - 1)
                {
                    int iprime = i - 1;
                    int jprime = j - 1;
                    int kprime = k - 1;

                    int l = kprime * nx * ny +
                            jprime * nx + iprime;

                    value = u[l];
                }

                // Dirichlet boundary points
                else
                {
                    BoundaryFace face;

                    // Priority: X faces, then Y, then Z
                    if (i == 0)
                        face = XMIN;
                    else if (i == Nx - 1)
                        face = XMAX;
                    else if (j == 0)
                        face = YMIN;
                    else if (j == Ny - 1)
                        face = YMAX;
                    else if (k == 0)
                        face = ZMIN;
                    else
                        face = ZMAX;

                    if (bcs[face].type != BC_DIRICHLET ||
                        bcs[face].function == NULL)
                    {
                        fprintf(stderr,
                                "Invalid Dirichlet BC on face %d\n",
                                face);
                        fclose(fp);
                        return;
                    }

                    value = bcs[face].function(
                        x, y, z, bcs[face].context);
                }

                fprintf(fp, "%.15e\n", value);
            }
        }
    }

    fclose(fp);

    printf("VTK file written: %s\n", filename);
}
