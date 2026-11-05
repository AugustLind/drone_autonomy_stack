#include "navigator/path_follower.hpp"

#include <algorithm>
#include <cmath>

VelocityCmd follow_segment(
    const Waypoint& a, const Waypoint& b, float px, float py, float pz,
    const FollowerParams& params) {
  VelocityCmd cmd;

  const auto dx = static_cast<float>(b.x - a.x);
  const auto dy = static_cast<float>(b.y - a.y);
  const float len = std::hypot(dx, dy);

  const float altitude_error = static_cast<float>(-b.z) - pz;
  const bool altitude_done = std::abs(altitude_error) <= params.altitude_tolerance;
  const float vz = params.altitude_gain * altitude_error;
  cmd.vz = std::clamp(vz, -params.max_vertical_speed, params.max_vertical_speed);

  if (len < 1e-3f) {
    const float ex = static_cast<float>(b.x) - px;
    const float ey = static_cast<float>(b.y) - py;
    cmd.vx = params.cross_track_gain * ex;
    cmd.vy = params.cross_track_gain * ey;
    const float speed = std::hypot(cmd.vx, cmd.vy);
    if (speed > params.max_speed) {
      cmd.vx *= params.max_speed / speed;
      cmd.vy *= params.max_speed / speed;
    }
    cmd.yaw = NAN;
    cmd.segment_done = std::hypot(ex, ey) <= params.lateral_tolerance && altitude_done;
    return cmd;
  }

  const float tx = dx / len;
  const float ty = dy / len;
  const float nx = -ty;
  const float ny = tx;

  const float rx = px - static_cast<float>(a.x);
  const float ry = py - static_cast<float>(a.y);
  const float along = (rx * tx) + (ry * ty);
  const float cross = (rx * nx) + (ry * ny);
  const float remaining = len - along;

  const float brake = std::clamp(remaining / params.slowdown_dist, params.min_speed_ratio, 1.0f);
  const float v_along = remaining < params.done_dist ? 0.0f : params.cruise_speed * brake;
  const float v_cross = -params.cross_track_gain * cross;

  float vx = (v_along * tx) + (v_cross * nx);
  float vy = (v_along * ty) + (v_cross * ny);

  const float speed = std::hypot(vx, vy);
  if (speed > params.max_speed) {
    vx *= params.max_speed / speed;
    vy *= params.max_speed / speed;
  }

  cmd.vx = vx;
  cmd.vy = vy;
  cmd.yaw = std::atan2(ty, tx);
  cmd.segment_done =
      remaining < params.done_dist && std::abs(cross) <= params.lateral_tolerance && altitude_done;
  return cmd;
}
