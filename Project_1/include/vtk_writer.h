
#ifndef VTK_WRITER_H
#define VTK_WRITER_H

void write_vtk_2D(const char *filename,
                  int nx, int ny,
                  double dx, double dy,
                  const double *u);
void write_vtk_3D(const char *filename, int nx, int ny, int nz,
                  double dx, double dy, double dz, const double *u);
#endif
