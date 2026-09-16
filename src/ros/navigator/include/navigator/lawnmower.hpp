#pragma once
#include <cmath>
#include <vector>

struct Point2D {
  double x{0.0};
  double y{0.0};
};

struct Area {
  std::vector<Point2D> corners;
};

struct Waypoint {
  double x{0.0};
  double y{0.0};
  double z{0.0};
};

std::vector<Waypoint> generate_lawnmower(const Area &area, double swath_width,
                                         double altitude);
