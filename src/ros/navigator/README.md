# navigator

A small header/library package for coverage path planning and path following. No ROS node — just a `navigator` CMake target that other packages (currently `fsm`) link against.

## API

`include/navigator/lawnmower.hpp`:

- `Point2D`, `Area` (a polygon of corners in the local NED frame — a rectangle is a 4-corner `Area`), `Waypoint` (x, y, z).
- `generate_lawnmower(area, swath_width, altitude)` — generates a boustrophedon ("lawnmower") coverage path across `area`, with parallel legs `swath_width` apart, at a fixed `altitude`. Expects `area.corners` in `{bottom_left, bottom_right, top_left, top_right}` order.

`include/navigator/path_follower.hpp`:

- `VelocityCmd` — NED velocity `vx, vy, vz` [m/s], `yaw` [rad] and a `segment_done` flag.
- `FollowerParams` — tuning for the follower (all exposed as `follower.*` parameters by `fsm`):

  | Field | Default | Description |
  | --- | --- | --- |
  | `cruise_speed` | 3.0 | along-track speed [m/s] |
  | `max_speed` | 5.0 | horizontal speed limit [m/s] |
  | `max_vertical_speed` | 1.5 | vertical speed limit [m/s] |
  | `cross_track_gain` | 0.8 | $k_e$ [1/s] |
  | `altitude_gain` | 1.0 | $k_z$ [1/s] |
  | `slowdown_dist` | 3.0 | $d_{\text{slow}}$, start braking this far from the segment end [m] |
  | `min_speed_ratio` | 0.2 | $k_{\min}$, fraction of cruise speed kept while braking |
  | `done_dist` | 0.3 | segment is done when this close to its end [m] |

- `follow_segment(a, b, px, py, pz, params)` — velocity command that tracks the line from `a` to `b`. Waypoints use z-up altitude; the position `px, py, pz` is in PX4 local NED.

## Use

```cpp
#include "navigator/lawnmower.hpp"
#include "navigator/path_follower.hpp"

Area area;
area.corners = {{0, 0}, {50, 0}, {0, 100}, {50, 100}};
std::vector<Waypoint> path = generate_lawnmower(area, /*swath_width=*/5.0, /*altitude=*/10.0);

// Every control tick, follow the current segment and advance when it is done.
VelocityCmd cmd = follow_segment(path[i], path[i + 1], x, y, z, params);
if (cmd.segment_done) {
  i++;
}
```

## Path follower math

The follower tracks the line between two waypoints instead of flying to the points themselves. This keeps the legs straight and evenly spaced.

### Segment frame

For a segment from $\mathbf{a}$ to $\mathbf{b}$ in the horizontal plane, with the vehicle at $\mathbf{p}$:

$$
\mathbf{d} = \mathbf{b} - \mathbf{a}, \qquad
L = \lVert \mathbf{d} \rVert, \qquad
\hat{\mathbf{t}} = \frac{\mathbf{d}}{L}, \qquad
\hat{\mathbf{n}} = \begin{bmatrix} -t_y \\ t_x \end{bmatrix}
$$

$\hat{\mathbf{t}}$ points along the segment and $\hat{\mathbf{n}}$ is perpendicular to it. Projecting the vehicle's offset from the start of the segment onto these gives:

$$
\mathbf{r} = \mathbf{p} - \mathbf{a}, \qquad
s = \mathbf{r} \cdot \hat{\mathbf{t}}, \qquad
e = \mathbf{r} \cdot \hat{\mathbf{n}}, \qquad
d_{\text{rem}} = L - s
$$

- $s$ is the along-track progress.
- $e$ is the signed cross-track error (distance from the line).
- $d_{\text{rem}}$ is the distance left to the end of the segment.

### Horizontal velocity

The command is an along-track speed plus a correction back toward the line:

$$
v_{\parallel} = v_{\text{cruise}} \cdot \operatorname{clamp}\!\left(\frac{d_{\text{rem}}}{d_{\text{slow}}},\ k_{\min},\ 1\right)
\qquad
v_{\perp} = -k_e \, e
$$

$$
\mathbf{v}_{xy} = v_{\parallel} \, \hat{\mathbf{t}} + v_{\perp} \, \hat{\mathbf{n}}
$$

The vehicle flies at `cruise_speed` until it is `slowdown_dist` from the end of the segment. It then slows linearly, but never below `min_speed_ratio` of cruise speed. The cross-track term makes $e$ decay exponentially with time constant $1 / k_e$ (`cross_track_gain`). Finally $\mathbf{v}_{xy}$ is scaled down if its magnitude exceeds `max_speed`.

### Vertical velocity

Altitude is held by a proportional controller in NED, where $z$ is positive down, so the target is $-h_b$ for a waypoint altitude $h_b$:

$$
v_z = \operatorname{clamp}\!\left(k_z \,(-h_b - p_z),\ -v_{z,\max},\ v_{z,\max}\right)
$$

### Heading and switching

The yaw setpoint faces along the segment, $\psi = \operatorname{atan2}(t_y, t_x)$. The segment is done when $d_{\text{rem}} <$ `done_dist`. Because this uses along-track progress rather than distance to the point, the follower still switches segments if the vehicle passes the end of the segment off to the side.

A segment shorter than 1 mm is reported as done immediately, with only the vertical command and a NaN yaw.
