#pragma once
#include "navigator/lawnmower.hpp"

struct VelocityCmd {
  float vx{0.0f};   // NED north [m/s]
  float vy{0.0f};   // NED east [m/s]
  float vz{0.0f};   // NED down [m/s]
  float yaw{0.0f};  // heading along the segment [rad]
  bool segment_done{false};
};

struct FollowerParams {
  float cruise_speed{3.0f};        // along-track speed [m/s]
  float max_speed{5.0f};           // horizontal speed limit [m/s]
  float max_vertical_speed{1.5f};  // vertical speed limit [m/s]
  float cross_track_gain{0.8f};    // [1/s]
  float altitude_gain{1.0f};       // [1/s]
  float slowdown_dist{3.0f};       // start braking this far from segment end [m]
  float min_speed_ratio{0.2f};     // fraction of cruise speed kept while braking
  float done_dist{0.3f};           // segment is done when this close to its end [m]
};

// Computes a velocity command that tracks the straight line from a to b.
// Waypoints use z-up altitude; position px, py, pz is in PX4 local NED.
VelocityCmd follow_segment(
    const Waypoint& a, const Waypoint& b, float px, float py, float pz,
    const FollowerParams& params = FollowerParams{});
