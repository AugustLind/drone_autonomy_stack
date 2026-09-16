#include "navigator/lawnmower.hpp"

std::vector<Waypoint> generate_lawnmower(const Area &area, double swath_width,
                                         double altitude) {
  std::vector<Waypoint> path;

  Point2D bottom_left = area.corners.at(0);
  Point2D bottom_right = area.corners.at(1);
  Point2D top_left = area.corners.at(2);
  Point2D top_right = area.corners.at(3);

  double total_height = std::abs(top_left.y - bottom_left.y);

  int num_rows = static_cast<int>(std::ceil(total_height / swath_width));
  if (num_rows < 2)
    num_rows = 2;

  for (int i = 0; i < num_rows; i++) {
    double t = static_cast<double>(i) / (num_rows - 1);

    Waypoint left_pt = {top_left.x + t * (bottom_left.x - top_left.x),
                        top_left.y + t * (bottom_left.y - top_left.y),
                        altitude};

    Waypoint right_pt = {top_right.x + t * (bottom_right.x - top_right.x),
                         top_right.y + t * (bottom_right.y - top_right.y),
                         altitude};

    if (i % 2 == 0) {
      path.push_back(left_pt);
      path.push_back(right_pt);
    } else {
      path.push_back(right_pt);
      path.push_back(left_pt);
    }
  }

  return path;
}
