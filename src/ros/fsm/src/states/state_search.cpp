#include <cmath>

#include "fsm/fsm.hpp"

void FSM::handle_state_search() {
  if (search_path_.empty()) {
    Area area;
    area.corners.push_back({0.0, 0.0});    // bottom_left
    area.corners.push_back({20.0, 0.0});   // bottom_right
    area.corners.push_back({0.0, 50.0});   // top_left
    area.corners.push_back({20.0, 50.0});  // top_right

    search_path_ = generate_lawnmower(area, 5.0, 10.0);

    search_path_.insert(
        search_path_.begin(), Waypoint{current_x_, current_y_, search_path_.front().z});
    search_waypoint_idx_ = 0;
    RCLCPP_INFO(this->get_logger(), "Search path generated: %zu waypoints.", search_path_.size());
  }

  publish_offboard_control_mode(ControlMode::VELOCITY);

  if (search_waypoint_idx_ + 1 >= search_path_.size()) {
    RCLCPP_INFO(this->get_logger(), "Search complete. Returning.");
    current_state_ = State::RETURN;
    search_path_.clear();
    return;
  }

  if (!local_position_fresh()) {
    RCLCPP_WARN_THROTTLE(
        this->get_logger(), *this->get_clock(), 1000, "Local position stale. Holding.");
    publish_velocity_setpoint(VelocityCmd{0.0f, 0.0f, 0.0f, NAN, false});
    return;
  }

  const Waypoint& from = search_path_[search_waypoint_idx_];
  const Waypoint& to = search_path_[search_waypoint_idx_ + 1];
  const VelocityCmd cmd = follow_segment(from, to, current_x_, current_y_, current_altitude_);
  publish_velocity_setpoint(cmd);

  if (nav_state_ != px4_msgs::msg::VehicleStatus::NAVIGATION_STATE_OFFBOARD) {
    // param1 = 1 (custom mode enabled), param2 = 6 (PX4_CUSTOM_MAIN_MODE_OFFBOARD)
    publish_vehicle_command(px4_msgs::msg::VehicleCommand::VEHICLE_CMD_DO_SET_MODE, 1.0f, 6.0f);
  }

  if (cmd.segment_done) {
    RCLCPP_INFO(
        this->get_logger(), "Completed segment %zu/%zu.", search_waypoint_idx_ + 1,
        search_path_.size() - 1);
    search_waypoint_idx_++;
  }
}
