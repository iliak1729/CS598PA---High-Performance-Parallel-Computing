
#ifndef VTK_WRITER_H
#define VTK_WRITER_H

void write_vtk_2D(const char *filename,
                  int nx, int ny,
                  double dx, double dy,
                  const double *u);

#endif
