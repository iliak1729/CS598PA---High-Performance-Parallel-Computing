
#include <stdio.h>
#include <stdlib.h>
#include "vtk_writer.h"

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
