# navigator

A small header/library package for coverage path planning. No ROS node — just a `navigator` CMake target that other packages (currently `fsm`) link against.

## API

`include/navigator/lawnmower.hpp`:

- `Point2D`, `Area` (a polygon of corners in the local NED frame — a rectangle is a 4-corner `Area`), `Waypoint` (x, y, z).
- `generate_lawnmower(area, swath_width, altitude)` — generates a boustrophedon ("lawnmower") coverage path across `area`, with parallel legs `swath_width` apart, at a fixed `altitude`. Expects `area.corners` in `{bottom_left, bottom_right, top_left, top_right}` order.

## Use

```cpp
#include "navigator/lawnmower.hpp"

Area area;
area.corners = {{0, 0}, {50, 0}, {0, 100}, {50, 100}};
std::vector<Waypoint> path = generate_lawnmower(area, /*swath_width=*/5.0, /*altitude=*/10.0);
```
