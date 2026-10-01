#include "fsm/fsm.hpp"

void FSM::handle_state_return() {
  const Waypoint home = {0.0, 0.0, return_altitude_};
  publish_trajectory_setpoint(home);

  publish_offboard_control_mode();

  if (reached_waypoint(home)) {
    RCLCPP_INFO(this->get_logger(), "Reached home. Landing.");
    current_state_ = State::LANDING;
    return;
  }
}
