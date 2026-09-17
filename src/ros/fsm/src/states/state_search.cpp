#include "fsm/fsm.hpp"

void FSM::handle_state_search() {
  if (search_path_.empty()) {
    Area area;
    area.corners.push_back({0.0, 0.0});    // bottom_left
    area.corners.push_back({20.0, 0.0});   // bottom_right
    area.corners.push_back({0.0, 50.0});   // top_left
    area.corners.push_back({20.0, 50.0});  // top_right

    search_path_ = generate_lawnmower(area, 5.0, 10.0);
    search_waypoint_idx_ = 0;
    RCLCPP_INFO(this->get_logger(), "Search path generated: %zu waypoints.", search_path_.size());
  }

  publish_offboard_control_mode();

  if (search_waypoint_idx_ >= search_path_.size()) {
    RCLCPP_INFO(this->get_logger(), "Search complete. Returning.");
    current_state_ = State::RETURN;
    search_path_.clear();
    return;
  }

  const Waypoint& target = search_path_[search_waypoint_idx_];
  publish_trajectory_setpoint(target);

  if (nav_state_ != px4_msgs::msg::VehicleStatus::NAVIGATION_STATE_OFFBOARD) {
    // param1 = 1 (custom mode enabled), param2 = 6 (PX4_CUSTOM_MAIN_MODE_OFFBOARD)
    publish_vehicle_command(px4_msgs::msg::VehicleCommand::VEHICLE_CMD_DO_SET_MODE, 1.0f, 6.0f);
  }

  if (reached_waypoint(target)) {
    RCLCPP_INFO(
        this->get_logger(), "Reached waypoint %zu/%zu.", search_waypoint_idx_ + 1,
        search_path_.size());
    search_waypoint_idx_++;
  }
}
