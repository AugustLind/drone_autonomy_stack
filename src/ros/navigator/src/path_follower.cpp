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

  const float vz = params.altitude_gain * (static_cast<float>(-b.z) - pz);
  cmd.vz = std::clamp(vz, -params.max_vertical_speed, params.max_vertical_speed);

  if (len < 1e-3f) {
    cmd.yaw = NAN;
    cmd.segment_done = true;
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
  const float v_along = params.cruise_speed * brake;
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
  cmd.segment_done = remaining < params.done_dist;
  return cmd;
}
